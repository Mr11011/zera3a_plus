import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../data/inventory_product_model.dart';
import '../data/purchase_batch_model.dart';
import 'general_inventory_states.dart';

class GeneralInventoryCubit extends Cubit<GeneralInventoryStates> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  GeneralInventoryCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(GeneralInventoryInitial());

  // --- PART 1: FETCHING DATA ---

  Future<void> fetchProducts(
      {String sortBy = 'itemName', bool descending = false}) async {
    emit(GeneralInventoryLoading());
    try {
      final snapshot = await _firestore
          .collection('inventory_products')
          .orderBy(sortBy, descending: descending)
          .get();
      final products = snapshot.docs
          .map((doc) => InventoryProduct.fromFirestore(doc))
          .toList();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(GeneralInventoryError("فشل في تحميل قائمة الأصناف"));
    }
  }

  Future<void> fetchProductDetails({required String productId}) async {
    emit(GeneralInventoryLoading());
    try {
      final productDoc = await _firestore
          .collection('inventory_products')
          .doc(productId)
          .get();
      if (!productDoc.exists) {
        throw Exception("الصنف غير موجود");
      }
      final product = InventoryProduct.fromFirestore(productDoc);

      final batchesSnapshot = await productDoc.reference
          .collection('batches')
          .orderBy('purchaseDate', descending: true)
          .get();
      final batches = batchesSnapshot.docs
          .map((doc) => PurchaseBatch.fromFirestore(doc))
          .toList();

      emit(ProductDetailsLoaded(product, batches));
    } catch (e) {
      emit(GeneralInventoryError("فشل في تحميل تفاصيل الصنف"));
    }
  }

  // --- PART 2: CREATING DATA ---

  Future<void> createNewProductWithFirstBatch({
    required String itemName,
    required String category,
    required String unit,
    required PurchaseBatch firstBatch,
  }) async {
    emit(GeneralInventoryLoading());
    try {
      final newProductRef = _firestore.collection('inventory_products').doc();
      final newBatchRef = newProductRef.collection('batches').doc();

      final newProduct = InventoryProduct(
        id: newProductRef.id,
        itemName: itemName,
        category: category,
        unit: unit,
        totalStock: firstBatch.initialQuantity,
        totalInitialStock: firstBatch.initialQuantity,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.set(newProductRef, {
          ...newProduct.toFirestore(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        transaction.set(newBatchRef, firstBatch.toFirestore());
      });
      await fetchProducts();
      emit(GeneralInventorySuccess("تم إنشاء الصنف وإضافة الشحنة بنجاح"));
    } catch (e) {
      emit(GeneralInventoryError("فشل في إنشاء الصنف الجديد"));
    }
  }

  Future<void> addPurchaseBatch({
    required String productId,
    required PurchaseBatch batchData,
  }) async {
    emit(GeneralInventoryLoading());
    try {
      final productRef =
          _firestore.collection('inventory_products').doc(productId);
      final newBatchRef = productRef.collection('batches').doc();

      await _firestore.runTransaction((transaction) async {
        transaction.set(newBatchRef, batchData.toFirestore());
        transaction.update(productRef, {
          'totalStock': FieldValue.increment(batchData.currentQuantity),
          'totalInitialStock': FieldValue.increment(batchData.initialQuantity),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      emit(GeneralInventorySuccess("تمت إضافة الشحنة بنجاح"));
    } catch (e) {
      emit(GeneralInventoryError("فشل في إضافة الشحنة الجديدة"));
    }
  }

  // --- PART 3: MODIFYING DATA ---

  Future<void> updateProductDetails({
    required String productId,
    required Map<String, dynamic> updatedData,
  }) async {
    emit(GeneralInventoryLoading());
    try {
      await _firestore
          .collection('inventory_products')
          .doc(productId)
          .update(updatedData);
      emit(GeneralInventoryItemUpdated());
      await fetchProducts();
    } catch (e) {
      debugPrint(e.toString());
      emit(GeneralInventoryError("فشل في تعديل بيانات الصنف"));
    }
  }

  /// --- NEW FUNCTION TO EDIT A BATCH ---
  Future<void> updatePurchaseBatch({
    required String productId,
    required String batchId,
    required Map<String, dynamic> updatedData,
  }) async {
    emit(GeneralInventoryLoading());
    try {
      final productRef =
          _firestore.collection('inventory_products').doc(productId);
      final batchRef = productRef.collection('batches').doc(batchId);

      await _firestore.runTransaction((transaction) async {
        // 1. Get the old batch data to calculate the difference.
        final oldBatchDoc = await transaction.get(batchRef);
        if (!oldBatchDoc.exists) {
          throw Exception("This batch does not exist.");
        }
        final oldBatchData = PurchaseBatch.fromFirestore(oldBatchDoc);

        // 2. Calculate the difference between old and new quantities.
        final double initialQtyDiff =
            (updatedData['initialQuantity'] as double) -
                oldBatchData.initialQuantity;
        final double currentQtyDiff =
            (updatedData['currentQuantity'] as double) -
                oldBatchData.currentQuantity;

        // 3. Recalculate cost per unit if necessary.
        if (updatedData.containsKey('totalCost') ||
            updatedData.containsKey('initialQuantity')) {
          final double totalCost =
              updatedData['totalCost'] ?? oldBatchData.totalCost;
          final double initialQuantity =
              updatedData['initialQuantity'] ?? oldBatchData.initialQuantity;
          if (initialQuantity > 0) {
            updatedData['costPerUnit'] = totalCost / initialQuantity;
          }
        }

        // 4. Update the batch document itself.
        transaction.update(batchRef, updatedData);

        // 5. Update the parent product's totals with the calculated differences.
        transaction.update(productRef, {
          'totalInitialStock': FieldValue.increment(initialQtyDiff),
          'totalStock': FieldValue.increment(currentQtyDiff),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      emit(GeneralInventorySuccess("تم تعديل الشحنة بنجاح"));
    } catch (e) {
      emit(GeneralInventoryError("فشل في تعديل الشحنة"));
    }
  }

  Future<void> deletePurchaseBatch({
    required String productId,
    required PurchaseBatch batchToDelete,
  }) async {
    emit(GeneralInventoryLoading());
    try {
      final productRef =
          _firestore.collection('inventory_products').doc(productId);
      final batchRef = productRef.collection('batches').doc(batchToDelete.id);

      await _firestore.runTransaction((transaction) async {
        transaction.delete(batchRef);
        transaction.update(productRef, {
          'totalStock': FieldValue.increment(-batchToDelete.currentQuantity),
          'totalInitialStock':
              FieldValue.increment(-batchToDelete.initialQuantity),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      emit(GeneralInventorySuccess("تم حذف الشحنة بنجاح"));
    } catch (e) {
      emit(GeneralInventoryError("فشل في حذف الشحنة"));
    }
  }

  Future<void> deleteProduct({required String productId}) async {
    emit(GeneralInventoryLoading());
    try {
      final productRef =
          _firestore.collection('inventory_products').doc(productId);
      final batchesSnapshot = await productRef.collection('batches').get();

      final batch = _firestore.batch();

      for (final doc in batchesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(productRef);

      await batch.commit();

      emit(GeneralInventoryItemDeleted());
      await fetchProducts();
    } catch (e) {
      emit(GeneralInventoryError("فشل في حذف الصنف"));
    }
  }
}
