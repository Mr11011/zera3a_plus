import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zera3a/feature/workers/workers_model.dart';
import 'package:zera3a/feature/workers/workers_states.dart';

//
// class LaborCubit extends Cubit<LaborStates> {
//   final FirebaseAuth _firebaseAuth;
//   final FirebaseFirestore _firestore;
//
//   LaborCubit({
//     required FirebaseAuth firebaseAuth,
//     required FirebaseFirestore firestore,
//   })  : _firebaseAuth = firebaseAuth,
//         _firestore = firestore,
//         super(LaborInitState());
//
//   Future<void> fetchLaborData(String plotId) async {
//     emit(LaborLoadingState());
//     try {
//       final snapshot = await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('activities')
//           .where('labor', isNotEqualTo: null)
//           .orderBy('labor.date', descending: true)
//           .get();
//
//       final laborList = snapshot.docs.map((doc) {
//         final data = doc.data()['labor'] as Map<String, dynamic>;
//         return LaborModel.fromJson(data);
//       }).toList();
//
//       emit(LaborHistoryLoadedState(laborList));
//     } catch (e) {
//       emit(LaborErrorState(errorMessage: "فشل في تحميل سجل العمالة"));
//     }
//   }
//
//   Future<void> addLaborData({
//     required int fixedWorkersCount,
//     required int fixedWorkersCost,
//     required int temporaryWorkersCount,
//     required int temporaryWorkersCost,
//     required String plotId,
//     required int fixedWorkersDays,
//     required int temporaryWorkersDays,
//   }) async {
//     final today = DateTime.now();
//     final dateKey = DateFormat('yyyy-MM-dd').format(today);
//     emit(LaborLoadingState());
//     try {
//       final user = _firebaseAuth.currentUser;
//       if (user == null) {
//         emit(LaborErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
//         return;
//       }
//
//       // Calculate total cost based on days worked
//       final fixedTotalCost = fixedWorkersCost * fixedWorkersDays;
//       final temporaryTotalCost = temporaryWorkersCost * temporaryWorkersDays;
//       final totalLaborCost = fixedTotalCost + temporaryTotalCost;
//
//       final laborData = LaborModel(
//         fixedWorkersCount: fixedWorkersCount,
//         fixedWorkersCost: fixedWorkersCost,
//         temporaryWorkersCount: temporaryWorkersCount,
//         temporaryWorkersCost: temporaryWorkersCost,
//         totalLaborCost: totalLaborCost,
//         date: DateTime.now(),
//         employeeId: user.uid,
//         plotId: plotId,
//         fixedWorkersDays: fixedWorkersDays,
//         temporaryWorkersDays: temporaryWorkersDays,
//       );
//
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('activities')
//           .doc(dateKey)
//           .set({
//         'labor': laborData.toJson(),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       final totalDays = fixedWorkersDays + temporaryWorkersDays;
//       final totalWorkers = fixedWorkersCount + temporaryWorkersCount;
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('dailySummary')
//           .doc(dateKey)
//           .set({
//         'totalCost': FieldValue.increment(totalLaborCost),
//         // 'laborFixedWorkers': FieldValue.increment(fixedWorkersCount),
//         // 'laborTemporaryWorkers': FieldValue.increment(temporaryWorkersCount),
//         'totalWorkers': FieldValue.increment(totalWorkers),
//         'laborTotalDays': FieldValue.increment(totalDays),
//         'laborTotalCost': FieldValue.increment(totalLaborCost),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       await fetchLaborData(plotId);
//     } catch (e) {
//       emit(LaborErrorState(errorMessage: "فشل في إضافة بيانات العمالة"));
//     }
//   }
//
//   Future<void> deleteLaborData(String plotId, String docId) async {
//     emit(LaborLoadingState());
//     try {
//       final docSnapshot = await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('activities')
//           .doc(docId)
//           .get();
//       if (!docSnapshot.exists) {
//         emit(LaborErrorState(errorMessage: " بيانات العمالع غير موجودة"));
//         return;
//       }
//       final laborData = LaborModel.fromJson(docSnapshot.data()!['labor']);
//       final totalLaborCost = laborData.totalLaborCost;
//       final laborFixedWorkers = laborData.fixedWorkersCount;
//       final laborTemporaryWorkers = laborData.temporaryWorkersCount;
//       final totalDays =
//           laborData.fixedWorkersDays + laborData.temporaryWorkersDays;
//       final totalWorkers = laborFixedWorkers + laborTemporaryWorkers;
//       docSnapshot.reference.delete();
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('dailySummary')
//           .doc(docId)
//           .set({
//         'totalCost': FieldValue.increment(-totalLaborCost),
//         'totalWorkers': FieldValue.increment(-totalWorkers),
//         'laborTotalDays': FieldValue.increment(-totalDays),
//         'laborTotalCost': FieldValue.increment(-totalLaborCost),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//       emit(LaborDeletedState());
//       await fetchLaborData(plotId);
//     } catch (e) {
//       emit(LaborErrorState(errorMessage: "فشل في الحذف"));
//     }
//   }
// }

class LaborCubit extends Cubit<LaborStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  LaborCubit({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(LaborInitState());

  Future<void> fetchLaborData(String plotId) async {
    emit(LaborLoadingState());
    try {
      final snapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'labor')
          .orderBy('date', descending: true)
          .get();

      final laborList = snapshot.docs.map((doc) {
        return LaborModel.fromJson({...doc.data(), 'docId': doc.id});
      }).toList();

      emit(LaborHistoryLoadedState(laborList));
    } catch (e) {
      emit(LaborErrorState(errorMessage: "فشل في تحميل سجل العمالة"));
    }
  }

  Future<void> addLaborData({
    required int fixedWorkersCount,
    required int fixedWorkersCost,
    required int temporaryWorkersCount,
    required int temporaryWorkersCost,
    required String plotId,
    required int fixedWorkersDays,
    required int temporaryWorkersDays,
  }) async {
    final today = DateTime.now();
    emit(LaborLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(LaborErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
        return;
      }

      final fixedTotalCost =
          fixedWorkersCount * fixedWorkersCost * fixedWorkersDays;
      final temporaryTotalCost =
          temporaryWorkersCount * temporaryWorkersCost * temporaryWorkersDays;
      final totalLaborCost = fixedTotalCost + temporaryTotalCost;

      final laborData = LaborModel(
        docId: '',
        fixedWorkersCount: fixedWorkersCount,
        fixedWorkersCost: fixedWorkersCost,
        temporaryWorkersCount: temporaryWorkersCount,
        temporaryWorkersCost: temporaryWorkersCost,
        totalLaborCost: totalLaborCost,
        date: today,
        employeeId: user.uid,
        plotId: plotId,
        fixedWorkersDays: fixedWorkersDays,
        temporaryWorkersDays: temporaryWorkersDays,
      );

      // Add labor document with auto-generated ID
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .add({
        'type': 'labor',
        ...laborData.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final totalDays = fixedWorkersDays + temporaryWorkersDays;
      final totalWorkers = fixedWorkersCount + temporaryWorkersCount;
      final dateKey = DateFormat('yyyy-MM-dd').format(today);
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set({
        'totalCost': FieldValue.increment(totalLaborCost),
        'laborTotalWorkers': FieldValue.increment(totalWorkers),
        'laborTotalDays': FieldValue.increment(totalDays),
        'laborTotalCost': FieldValue.increment(totalLaborCost),
        'counts': {
          'inventory': FieldValue.increment(0),
          'irrigation': FieldValue.increment(0),
          'labor': FieldValue.increment(1),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await fetchLaborData(plotId);
    } catch (e) {
      emit(LaborErrorState(errorMessage: "فشل في إضافة بيانات العمالة"));
    }
  }

  Future<void> deleteLaborData(String plotId, String docId) async {
    emit(LaborLoadingState());
    try {
      final docSnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(docId)
          .get();
      if (!docSnapshot.exists) {
        emit(LaborErrorState(errorMessage: "بيانات العمالة غير موجودة"));
        return;
      }
      final laborData = LaborModel.fromJson(docSnapshot.data()!);
      final totalLaborCost = laborData.totalLaborCost;
      final totalWorkers =
          laborData.fixedWorkersCount + laborData.temporaryWorkersCount;
      final totalDays =
          laborData.fixedWorkersDays + laborData.temporaryWorkersDays;

      await docSnapshot.reference.delete();

      final dateKey = DateFormat('yyyy-MM-dd').format(laborData.date);
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set({
        'totalCost': FieldValue.increment(-totalLaborCost),
        'laborTotalWorkers': FieldValue.increment(-totalWorkers),
        'laborTotalDays': FieldValue.increment(-totalDays),
        'laborTotalCost': FieldValue.increment(-totalLaborCost),
        'counts': {
          'inventory': FieldValue.increment(0),
          'irrigation': FieldValue.increment(0),
          'labor': FieldValue.increment(-1),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      emit(LaborDeletedState());
      await fetchLaborData(plotId);
    } catch (e) {
      emit(LaborErrorState(errorMessage: "فشل في الحذف"));
    }
  }
}
