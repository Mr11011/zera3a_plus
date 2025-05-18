import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zera3a/feature/irrigation/irrigation_states.dart';
//
// class IrrigationCubit extends Cubit<IrrigationStates> {
//   final FirebaseAuth _firebaseAuth;
//   final FirebaseFirestore _firestore;
//
//   IrrigationCubit(
//       {required FirebaseAuth firebaseAuth,
//       required FirebaseFirestore firestore})
//       : _firebaseAuth = firebaseAuth,
//         _firestore = firestore,
//         super(IrrigationInitState());
//
//   Future<void> fetchIrrigationData(String plotId) async {
//     emit(IrrigationLoadingState());
//     try {
//       final snapshot = await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('activities')
//           .where('irrigation', isNotEqualTo: null)
//           .orderBy('irrigation.date', descending: true)
//           .get();
//
//       final irrigationList = snapshot.docs.map((doc) {
//         final data = doc.data()['irrigation'] as Map<String, dynamic>;
//         return {
//           'date': (data['date'] as Timestamp).toDate(),
//           'hours': data['hours'],
//           'unitCost': data['unitCost'],
//           'totalCost': data['totalCost'],
//         };
//       }).toList();
//
//       emit(IrrigationHistoryLoadedState(irrigationList));
//     } catch (e) {
//       emit(IrrigationErrorState(errorMessage: "فشل في تحميل سجل الري"));
//     }
//   }
//
//   Future<void> addIrrigationData(
//       int days, int hours, int cost, String plotId) async {
//     final today = DateTime.now();
//     final dateKey =
//         DateFormat('yyyy-MM-dd').format(today); // Format: "2025-04-16"
//     emit(IrrigationLoadingState());
//     try {
//       final user = _firebaseAuth.currentUser;
//       if (user == null) {
//         emit(IrrigationErrorState(errorMessage: "يرجى تسجيل الدخول اولاً"));
//         return;
//       }
//
//       final irrigationData = {
//         'date': DateTime.now().toUtc(),
//         'days': days,
//         'hours': hours,
//         'unitCost': cost,
//         'plotId': plotId,
//         'totalCost': days * hours * cost,
//         'employeeId': user.uid
//       };
//
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection("activities")
//           .doc(dateKey)
//           .set({
//         'irrigation': irrigationData,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       final int totalCost = days * hours * cost;
//       // Update dailySummary
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection("dailySummary")
//           .doc(dateKey)
//           .set({
//         'totalCost': FieldValue.increment(days * hours * cost),
//         'irrigationTotalCost': FieldValue.increment(totalCost),
//         'irrigationHours': FieldValue.increment(hours),
//         'irrigationDays': FieldValue.increment(days),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//       emit(IrrigationLoadedState());
//       await fetchIrrigationData(plotId);
//     } catch (e) {
//       emit(IrrigationErrorState(errorMessage: "فشل في إضافة البيانات"));
//     }
//   }
//
//   Future<void> deleteIrrigationData(String plotId, String docId) async {
//     emit(IrrigationLoadingState());
//
//     try {
//       final docSnapshot = await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('activities')
//           .doc(docId)
//           .get();
//
//       if (!docSnapshot.exists ||
//           docSnapshot.data() == null ||
//           docSnapshot.data()!['irrigation'] == null ||
//           !docSnapshot.data()!.containsKey('irrigation')) {
//         emit(IrrigationErrorState(errorMessage: "بيانات الري غير موجودة"));
//         return;
//       }
//
//       final irrigationData =
//           docSnapshot.data()!['irrigation'] as Map<String, dynamic>;
//       final hours = irrigationData['hours'] as int;
//       final days = irrigationData['days'] as int;
//       final totalCost = irrigationData['totalCost'] as int;
//
//       docSnapshot.reference.delete();
//
//       // Update dailySummary by decrementing the values
//       await _firestore
//           .collection('plots')
//           .doc(plotId)
//           .collection('dailySummary')
//           .doc(docId)
//           .set({
//         'totalCost': FieldValue.increment(-totalCost),
//         'irrigationTotalCost': FieldValue.increment(-totalCost),
//         'irrigationHours': FieldValue.increment(-hours),
//         'irrigationDays': FieldValue.increment(-days),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       emit(IrrigationDeletedState());
//       // Fetch updated history
//       await fetchIrrigationData(plotId);
//     } catch (e) {
//       emit(IrrigationErrorState(errorMessage: "فشل في الحذف"));
//     }
//   }
// }


class IrrigationCubit extends Cubit<IrrigationStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  IrrigationCubit({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(IrrigationInitState());

  Future<void> fetchIrrigationData(String plotId) async {
    emit(IrrigationLoadingState());
    try {
      final snapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .where('type', isEqualTo: 'irrigation')
          .orderBy('date', descending: true)
          .get();

      final irrigationList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': (data['date'] as Timestamp).toDate(),
          'hours': data['hours'] as int,
          'unitCost': data['unitCost'] as int,
          'totalCost': data['totalCost'] as int,
          'days': data['days'] as int,
          'docId': doc.id,
        };
      }).toList();

      emit(IrrigationHistoryLoadedState(irrigationList));
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في تحميل سجل الري"));
    }
  }

  Future<void> addIrrigationData(int days, int hours, int cost, String plotId) async {
    emit(IrrigationLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(IrrigationErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
        return;
      }

      final totalCost = days * hours * cost;
      final today = DateTime.now();
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .add({
        'type': 'irrigation',
        'date': today.toUtc(),
        'days': days,
        'hours': hours,
        'unitCost': cost,
        'totalCost': totalCost,
        'employeeId': user.uid,
        'plotId': plotId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final dateKey = DateFormat('yyyy-MM-dd').format(today);
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set({
        'totalCost': FieldValue.increment(totalCost),
        'irrigationHours': FieldValue.increment(hours),
        'irrigationDays': FieldValue.increment(days),
        'irrigationTotalCost': FieldValue.increment(totalCost),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      emit(IrrigationLoadedState());
      await fetchIrrigationData(plotId);
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في إضافة البيانات"));
    }
  }

  Future<void> deleteIrrigationData(String plotId, String docId) async {
    emit(IrrigationLoadingState());
    try {
      final docSnapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .doc(docId)
          .get();
      if (!docSnapshot.exists) {
        emit(IrrigationErrorState(errorMessage: "بيانات الري غير موجودة"));
        return;
      }

      final data = docSnapshot.data()!;
      final hours = data['hours'] as int;
      final days = data['days'] as int;
      final totalCost = data['totalCost'] as int;

      await docSnapshot.reference.delete();

      final dateKey = DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate());
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set({
        'totalCost': FieldValue.increment(-totalCost),
        'irrigationHours': FieldValue.increment(-hours),
        'irrigationDays': FieldValue.increment(-days),
        'irrigationTotalCost': FieldValue.increment(-totalCost),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      emit(IrrigationDeletedState());
      await fetchIrrigationData(plotId);
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في الحذف"));
    }
  }
}
