import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../data/inventory_model.dart';
import '../generalInventory/data/general_inventory_model.dart';
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

  // This function now fetches BOTH the plot's history and the available general inventory.
  Future<void> fetchInventoryPageData(String plotId) async {
    emit(InventoryLoadingState());
    try {
      // 1. Fetch the plot's usage history (as before)
      final historySnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'inventory_usage')
          .orderBy('date', descending: true)
          .get();

      final historyList = historySnapshot.docs.map((doc) {
        return InventoryModel.fromJson({...doc.data(), 'docId': doc.id});
      }).toList();

      // 2. Fetch all available items from the general inventory
      final generalInventorySnapshot =
      await _firestore.collection('general_inventory').get();

      final availableItems = generalInventorySnapshot.docs
          .map((doc) => PlotInventory.fromFirestore(doc))
      // Only show items that are in stock
          .where((item) => item.currentQuantity > 0)
          .toList();

      // 3. Emit the new state containing both lists
      emit(InventoryPageLoaded(
          history: historyList, availableItems: availableItems));
    } catch (e) {
      emit(InventoryErrorState(errorMessage: "فشل في تحميل بيانات المخزن"));
    }
  }

  /// Adds an inventory usage log and atomically decreases the general stock.
  Future<void> addInventoryUsage({
    required String plotId,
    required PlotInventory item, // We now pass the whole item object
    required double quantityUsed,
  }) async {
    emit(InventoryLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(InventoryErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
        return;
      }

      // Define references to all documents that will be part of the transaction
      final generalItemRef =
      _firestore.collection('general_inventory').doc(item.id);
      final activityRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(); // Firestore generates the ID
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final summaryRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey);

      final totalCost = quantityUsed * item.costPerUnit;

      // Run the entire operation as an atomic transaction
      await _firestore.runTransaction((transaction) async {
        // 1. Read the current general inventory item to ensure it has enough stock
        final generalItemDoc = await transaction.get(generalItemRef);
        if (!generalItemDoc.exists) {
          throw Exception("الصنف غير موجود في المخزن العام");
        }
        final currentQuantity =
        (generalItemDoc.data()!['currentQuantity'] as num).toDouble();
        if (currentQuantity < quantityUsed) {
          throw Exception("الكمية المطلوبة أكبر من المتوفر في المخزن");
        }

        // 2. Create the new activity log for the plot
        transaction.set(activityRef, {
          'type': 'inventory_usage',
          'itemId': item.itemName, // Log the name for easy reading
          'generalInventoryId': item.id, // IMPORTANT: Link to the general item
          'quantityUsed': quantityUsed,
          'itemUnitCost': item.costPerUnit,
          'inventoryTotalCost': totalCost,
          'date': Timestamp.now(),
          'employeeId': user.uid,
          'plotId': plotId,
        });

        // 3. Update the daily summary for the plot
        transaction.set(
            summaryRef,
            {
              'inventoryTotalCost': FieldValue.increment(totalCost),
              'totalCost': FieldValue.increment(totalCost),
              'inventoryTotalQuantity': FieldValue.increment(quantityUsed),
              'lastUpdated': FieldValue.serverTimestamp(),
              'counts': {'inventory': FieldValue.increment(1)}
            },
            SetOptions(merge: true));

        // 4. Decrease the stock in the general inventory
        transaction.update(generalItemRef, {
          'currentQuantity': FieldValue.increment(-quantityUsed),
        });
      });

      emit(InventoryLoadedState()); // Signal success
      await fetchInventoryPageData(plotId); // Refresh the page data
    } catch (e) {
      emit(InventoryErrorState(errorMessage: e.toString()));
    }
  }

  /// Deletes an inventory usage log and atomically returns stock to the general inventory.
  Future<void> deleteInventoryUsage(
      {required String plotId, required InventoryModel usageLog}) async {
    emit(InventoryLoadingState());
    try {
      // Define references for the transaction
      final generalItemRef = _firestore
          .collection('general_inventory')
          .doc(usageLog.generalInventoryId); // Use the stored ID
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

      // Run the reversal as an atomic transaction
      await _firestore.runTransaction((transaction) async {
        // 1. Delete the activity log
        transaction.delete(activityRef);

        // 2. Reverse the daily summary update
        transaction.set(
            summaryRef,
            {
              'inventoryTotalCost':
              FieldValue.increment(-usageLog.inventoryTotalCost),
              'totalCost': FieldValue.increment(-usageLog.inventoryTotalCost),
              'inventoryTotalQuantity':
              FieldValue.increment(-usageLog.quantityUsed),
              'lastUpdated': FieldValue.serverTimestamp(),
              'counts': {'inventory': FieldValue.increment(-1)}
            },
            SetOptions(merge: true));

        // 3. Return the stock to the general inventory
        transaction.update(generalItemRef, {
          'currentQuantity': FieldValue.increment(usageLog.quantityUsed),
        });
      });

      emit(InventoryDeletedState());
      await fetchInventoryPageData(plotId);
    } catch (e) {
      emit(InventoryErrorState(errorMessage: "فشل في حذف البيانات"));
    }
  }
}
