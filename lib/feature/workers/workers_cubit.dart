import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zera3a/feature/workers/workers_model.dart';
import 'package:zera3a/feature/workers/workers_states.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../general_workers/data/contractors.dart';
import '../general_workers/data/fixed_workers.dart';

class PlotLaborCubit extends Cubit<PlotLaborState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  PlotLaborCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(PlotLaborInitial());

  String? get _userId => _firebaseAuth.currentUser?.uid;

  /// Fetches the plot's history AND the available workers/contractors
  Future<void> fetchPageData(String plotId) async {
    emit(PlotLaborLoading());
    try {
      if (_userId == null) throw Exception("User not logged in");

      // 1. Fetch the plot's labor history
      final historySnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'labor')
          .orderBy('date', descending: true)
          .get();
      final history = historySnapshot.docs
          .map((doc) => PlotLaborLog.fromFirestore(doc))
          .toList();

      // 2. Fetch the general list of fixed workers
      final workersSnapshot = await _firestore
          .collection('fixed_workers')
          // .where('ownerId', isEqualTo: _userId)
          .get();
      final fixedWorkers = workersSnapshot.docs
          .map((doc) => FixedWorker.fromFirestore(doc))
          .toList();

      // 3. Fetch the general list of contractors
      final contractorsSnapshot = await _firestore
          .collection('contractors')
          // .where('ownerId', isEqualTo: _userId)
          .get();
      final contractors = contractorsSnapshot.docs
          .map((doc) => Contractor.fromFirestore(doc))
          .toList();

      emit(PlotLaborPageLoaded(
        history: history,
        availableFixedWorkers: fixedWorkers,
        availableContractors: contractors,
      ));
    } catch (e) {
      emit(PlotLaborError("فشل في تحميل البيانات: ${e.toString()}"));
    }
  }

  /// Adds a new labor activity log and updates the daily summary
  Future<void> addLaborActivity({
    required String plotId,
    required String laborType,
    required String resourceId,
    required String resourceName,
    required double workerCount,
    required double days,
    required double costPerUnit,
  }) async {
    emit(PlotLaborLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final totalCost = workerCount * days * costPerUnit;
      final date = DateTime.now();

      final log = PlotLaborLog(
        docId: '',
        laborType: laborType,
        resourceId: resourceId,
        resourceName: resourceName,
        workerCount: workerCount,
        days: days,
        costPerUnit: costPerUnit,
        totalCost: totalCost,
        date: date,
        employeeId: user.uid,
        plotId: plotId,
      );

      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // Define references
      final activityRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc();
      final summaryRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey);

      // Run as a transaction
      await _firestore.runTransaction((transaction) async {
        // 1. Create the activity log
        transaction.set(activityRef, {
          ...log.toFirestore(),
          'date': FieldValue.serverTimestamp() // Use server time
        });

        // 2. Update the daily summary
        transaction.set(
            summaryRef,
            {
              'totalCost': FieldValue.increment(totalCost),
              'laborTotalWorkers': FieldValue.increment(workerCount),
              'laborTotalDays': FieldValue.increment(days),
              'laborTotalCost': FieldValue.increment(totalCost),
              'counts.labor': FieldValue.increment(1),
            },
            SetOptions(merge: true));
      });

      emit(PlotLaborSuccess("تم إضافة العمالة بنجاح"));
      await fetchPageData(plotId);
    } catch (e) {
      emit(PlotLaborError(e.toString()));
    }
  }

  /// Deletes a labor activity log and reverses the daily summary
  Future<void> deleteLaborActivity(String plotId, PlotLaborLog log) async {
    emit(PlotLaborLoading());
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.date);

      // Define references
      final activityRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(log.docId);
      final summaryRef = _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        // 1. Get the current summary to avoid negative counts
        final summaryDoc = await transaction.get(summaryRef);
        final currentCounts =
            (summaryDoc.data()?['counts'] as Map<String, dynamic>?) ?? {};
        final currentLaborCount =
            (currentCounts['labor'] as num?)?.toInt() ?? 0;

        // 2. Delete the activity log
        transaction.delete(activityRef);

        // 3. Update the summary
        transaction.set(
            summaryRef,
            {
              'totalCost': FieldValue.increment(-log.totalCost),
              'laborTotalWorkers': FieldValue.increment(-log.workerCount),
              'laborTotalDays': FieldValue.increment(-log.days),
              'laborTotalCost': FieldValue.increment(-log.totalCost),
              'counts.labor':
                  FieldValue.increment(currentLaborCount > 0 ? -1 : 0),
            },
            SetOptions(merge: true));
      });

      emit(PlotLaborDeleted());
      await fetchPageData(plotId);
    } catch (e) {
      emit(PlotLaborError("فشل في الحذف: ${e.toString()}"));
    }
  }
}
