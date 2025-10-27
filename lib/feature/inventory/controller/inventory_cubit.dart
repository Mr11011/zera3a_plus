import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../general_inventory/data/inventory_product_model.dart';
import '../../general_inventory/data/purchase_batch_model.dart';
import '../data/inventory_model.dart';

import 'inventory_states.dart';

class InventoryCubit extends Cubit<InventoryStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  InventoryCubit(
      {required FirebaseAuth firebaseAuth,
      required FirebaseFirestore firestore})
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(InventoryInitState());

  /// Fetches the plot's usage history AND the list of available products from the catalog.
  Future<void> fetchInventoryPageData(String plotId) async {
    emit(InventoryLoadingState());
    try {
      // 1. Fetch the plot's usage history
      final historySnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'inventory_usage')
          .orderBy('date', descending: true)
          .get();
      final historyList = historySnapshot.docs
          .map((doc) =>
              InventoryModel.fromJson({...doc.data(), 'docId': doc.id}))
          .toList();

      // 2. Fetch all available PRODUCTS from the product catalog
      final productsSnapshot = await _firestore
          .collection('inventory_products')
          .orderBy('itemName')
          .get();
      final availableProducts = productsSnapshot.docs
          .map((doc) => InventoryProduct.fromFirestore(doc))
          .where((product) =>
              product.totalStock > 0) // Only show products in stock
          .toList();

      // 3. Emit the state containing both lists
      emit(InventoryPageLoaded(
          history: historyList, availableProducts: availableProducts));
    } catch (e) {
      emit(InventoryErrorState(
          errorMessage: "فشل في تحميل بيانات المخزن: ${e.toString()}"));
    }
  }

  /// Adds an inventory usage log and atomically decreases stock from the correct batch (FIFO).
  Future<void> addInventoryUsage({
    required String plotId,
    required InventoryProduct product, // Pass the selected PRODUCT
    required double quantityUsed,
  }) async {
    emit(InventoryLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("يرجى تسجيل الدخول أولاً");

      // References
      final productRef =
          _firestore.collection('inventory_products').doc(product.id);
      final activityRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc();
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final summaryRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        // Step 1: Validate Product Stock
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists ||
            (productDoc.data()!['totalStock'] as num? ?? 0) < quantityUsed) {
          throw Exception(
              "الكمية المطلوبة (${quantityUsed} ${product.unit}) أكبر من المتوفر (${productDoc.data()?['totalStock'] ?? 0} ${product.unit})");
        }

        // Step 2: Find the Oldest Batch with Stock (FIFO)
        final batchesQuerySnapshot = await productRef
            .collection('batches')
            .where('currentQuantity', isGreaterThan: 0)
            .orderBy('purchaseDate') // Oldest first
            .limit(1)
            .get(); // Use get() inside transaction for reads

        if (batchesQuerySnapshot.docs.isEmpty) {
          throw Exception("خطأ: لا توجد شحنات متوفرة لهذا الصنف.");
        }

        final batchDocToUpdate = batchesQuerySnapshot.docs.first;
        final batchData = PurchaseBatch.fromFirestore(batchDocToUpdate);

        if (batchData.currentQuantity < quantityUsed) {
          // TODO: Implement multi-batch consumption logic if needed.
          throw Exception(
              "الكمية المطلوبة (${quantityUsed} ${product.unit}) أكبر من المتوفر في أقدم شحنة (${batchData.currentQuantity} ${product.unit}).");
        }

        final double totalCostForUsage = quantityUsed * batchData.costPerUnit;

        // Step 3: Record the Usage Activity
        final usageData = InventoryModel(
          docId: activityRef.id,
          itemId: product.itemName,
          productId: product.id,
          batchId: batchDocToUpdate.id,
          // Link to the specific batch
          quantityUsed: quantityUsed,
          itemUnitCost: batchData.costPerUnit,
          inventoryTotalCost: totalCostForUsage,
          date: DateTime.now(),
          // Will be replaced by server timestamp
          employeeId: user.uid,
          plotId: plotId,
        );
        // Use the model's toJson which includes the 'type'
        transaction.set(activityRef, {
          ...usageData.toJson(),
          'date': FieldValue.serverTimestamp(), // Use server time
        });

        // Step 4: Update Plot Daily Summary
        transaction.set(
            summaryRef,
            {
              'inventoryTotalCost': FieldValue.increment(totalCostForUsage),
              'totalCost': FieldValue.increment(totalCostForUsage),
              'inventoryTotalQuantity': FieldValue.increment(quantityUsed),
              'lastUpdated': FieldValue.serverTimestamp(),
              'counts.inventory': FieldValue.increment(1)
            },
            SetOptions(merge: true));

        // Step 5: Decrease Stock from the specific Batch
        transaction.update(batchDocToUpdate.reference, {
          'currentQuantity': FieldValue.increment(-quantityUsed),
        });

        // Step 6: Decrease Total Stock on the Product
        transaction.update(productRef, {
          'totalStock': FieldValue.increment(-quantityUsed),
          'lastUpdated': FieldValue.serverTimestamp(),
          // Also update product timestamp
        });
      });

      emit(InventoryLoadedState()); // Signal success
      await fetchInventoryPageData(plotId); // Refresh UI data
    } catch (e) {
      emit(InventoryErrorState(errorMessage: e.toString()));
    }
  }

  /// Deletes an inventory usage log and atomically returns stock to the correct batch.
  Future<void> deleteInventoryUsage({
    required String plotId,
    required InventoryModel usageLog, // This is the activity log to delete
  }) async {
    emit(InventoryLoadingState());
    try {
      // Validate IDs before proceeding
      if (usageLog.batchId.isEmpty || usageLog.productId.isEmpty) {
        throw Exception(
            "لا يمكن استرجاع المخزون لسجلات قديمة تفتقد معرف المنتج أو الشحنة.");
      }

      // References
      final productRef =
          _firestore.collection('inventory_products').doc(usageLog.productId);
      final batchRef = productRef.collection('batches').doc(usageLog.batchId);
      final activityRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(usageLog.docId);
      final dateKey = DateFormat('yyyy-MM-dd').format(usageLog.date);
      final summaryRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        // --- FIX: All READ operations must come first ---
        final summaryDoc = await transaction.get(summaryRef); // READ FIRST
        // (Optional) You could also read productRef and batchRef here if needed for validation

        // Now perform all the WRITE operations

        // --- Step 1: Delete the Activity Log ---
        transaction.delete(activityRef);

        // --- Step 2: Reverse the Plot Daily Summary Update ---
        // Use the data read at the beginning
        final currentCounts =
            (summaryDoc.data()?['counts'] as Map<String, dynamic>?) ?? {};
        final currentInvCount =
            (currentCounts['inventory'] as num?)?.toInt() ?? 0;

        transaction.set(
            summaryRef,
            {
              'inventoryTotalCost':
                  FieldValue.increment(-usageLog.inventoryTotalCost),
              'totalCost': FieldValue.increment(-usageLog.inventoryTotalCost),
              'inventoryTotalQuantity':
                  FieldValue.increment(-usageLog.quantityUsed),
              'counts.inventory':
                  FieldValue.increment(currentInvCount > 0 ? -1 : 0),
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // --- Step 3: Return Stock to the specific Batch ---
        transaction.update(batchRef, {
          'currentQuantity': FieldValue.increment(usageLog.quantityUsed),
        });

        // --- Step 4: Return Stock to the Product Total ---
        transaction.update(productRef, {
          'totalStock': FieldValue.increment(usageLog.quantityUsed),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      emit(InventoryDeletedState()); // Signal success for UI feedback
      await fetchInventoryPageData(plotId); // Refresh UI data
    } catch (e) {
      emit(InventoryErrorState(errorMessage: e.toString()));
    }
  }
}
