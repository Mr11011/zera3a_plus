import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' show DateFormat;
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

  Future<void> fetchInventoryData(String plotId) async {
    emit(InventoryLoadingState());
    try {
      final snapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'inventory_usage')
          .orderBy('date', descending: true)
          .get();

      final inventoryList = snapshot.docs.map((doc) {
        return InventoryModel.fromJson({...doc.data(), 'docId': doc.id});
      }).toList();
      emit(InventoryHistoryLoadedState(inventoryList));
    } catch (e) {
      emit(InventoryErrorState(errorMessage: "فشل في سِجل المخزن"));
    }
  }

  Future<void> addInventoryData(
      {required double quantity,
      required double unitCost,
      required String plotId,
      required String itemId}) async {
    emit(InventoryLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(InventoryErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
        return;
      }

      final inventoryData = InventoryModel(
        docId: '',
        itemId: itemId,
        quantityUsed: quantity,
        itemUnitCost: unitCost,
        inventoryTotalCost: quantity * unitCost,
        date: DateTime.now(),
        employeeId: user.uid,
        plotId: plotId,
      );

      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .add({
        'type': 'inventory_usage',
        ...inventoryData.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set({
        'inventoryTotalCost':
            FieldValue.increment(inventoryData.inventoryTotalCost),
        'inventoryTotalQuantity': FieldValue.increment(quantity),
        'lastUpdated': FieldValue.serverTimestamp(),
        'counts': {
          'inventory': FieldValue.increment(1),
          'irrigation': FieldValue.increment(0),
          'labor': FieldValue.increment(0),
        }
      }, SetOptions(merge: true));
      emit(InventoryLoadedState());
      await fetchInventoryData(plotId);
    } catch (e) {
      emit(InventoryErrorState(errorMessage: 'فشل في اضافة بيانات المخزن'));
    }
  }

  Future<void> deleteInventoryData(String plotId, String docId) async {
    emit(InventoryLoadingState());
    try {
      final docSnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(docId)
          .get();

      if (!docSnapshot.exists) {
        emit(InventoryErrorState(errorMessage: "بيانات المخزن غير موجودة"));
        return;
      }

      await docSnapshot.reference.delete();

      final inventoryData = InventoryModel.fromJson(docSnapshot.data()!);
      final totalCost = inventoryData.inventoryTotalCost;
      final quantityUsed = inventoryData.quantityUsed;
      final dateKey = DateFormat('yyyy-MM-dd').format(inventoryData.date);
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set(
              {
            'inventoryTotalCost': FieldValue.increment(-totalCost),
            'inventoryTotalQuantity': FieldValue.increment(-quantityUsed),
            'lastUpdated': FieldValue.serverTimestamp(),
            'counts': {
              'inventory': FieldValue.increment(-1),
              'irrigation': FieldValue.increment(0),
              'labor': FieldValue.increment(0),
            }
          },
              SetOptions(
                merge: true,
              ));

      emit(InventoryDeletedState());
      await fetchInventoryData(plotId);
    } catch (e) {
      emit(InventoryErrorState(errorMessage: "فشل في حذف البيانات"));
    }
  }
}
