import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zera3a/feature/irrigation/irrigation_states.dart';
import '../../core/di.dart';

class IrrigationCubit extends Cubit<IrrigationStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  IrrigationCubit({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(IrrigationInitState());

  Future<void> updateUnitCost(int cost, String plotId) async {
    emit(IrrigationLoadingState());
    try {
      await _firestore.collection('plots').doc(plotId).update({
        'unitCost': cost,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final sharedPreferences = sl<SharedPreferences>();
      sharedPreferences.setInt('unitCost$plotId', cost);

      emit(IrrigationUnitCostUpdatedState());
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: 'فشل في وضع قيمة ساعة الري'));
    }
  }

  Future<int> getUnitCost(String plotId) async {
    try {
      final fixedCost = sl<SharedPreferences>().getInt('unitCost$plotId');
      if (fixedCost != null) {
        return fixedCost;
      }

      final doc = await _firestore.collection('plots').doc(plotId).get();


      if (!doc.exists || doc.data()?['unitCost'] == null) {
        sl<SharedPreferences>().setInt('unitCost$plotId', 0);
        return 0;
      }
      final cost = doc.data()!['unitCost'] as int;
      sl<SharedPreferences>().setInt('unitCost$plotId', cost);

      return cost;
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في جلب تكلفة الري"));
      return 0;
    }
  }

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
          'hours': data['hours'] as double,
          'unitCost': data['unitCost'] as int,
          'totalCost': data['totalCost'] as double,
          'days': data['days'] as int,
          'docId': doc.id,
        };
      }).toList();

      emit(IrrigationHistoryLoadedState(irrigationList));
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في تحميل سجل الري"));
    }
  }

  Future<void> addIrrigationData({
    required int days,
    required double hours,
    required int cost,
    required String plotId,
    required DateTime date,
  }) async {
    emit(IrrigationLoadingState());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(IrrigationErrorState(errorMessage: "يرجى تسجيل الدخول أولاً"));
        return;
      }

      final totalCost = days * hours * cost;
      final selectedDate = date.toUtc(); // Use the provided date
      await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('activities')
          .add({
        'type': 'irrigation',
        'date': selectedDate,
        'days': days,
        'hours': hours,
        'unitCost': cost,
        'totalCost': totalCost,
        'employeeId': user.uid,
        'plotId': plotId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final dateKey = DateFormat('yyyy-MM-dd').format(date);
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
        'counts': {
          'inventory': FieldValue.increment(0),
          'irrigation': FieldValue.increment(1),
          'labor': FieldValue.increment(0),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await updateUnitCost(
        cost,
        plotId,
      );

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
      final hours = data['hours'] as double;
      final days = data['days'] as int;
      final totalCost = data['totalCost'] as double;

      await docSnapshot.reference.delete();

      final dateKey =
          DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate());
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
        'counts': {
          'inventory': FieldValue.increment(0),
          'irrigation': FieldValue.increment(-1),
          'labor': FieldValue.increment(0),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      emit(IrrigationDeletedState());
      await fetchIrrigationData(plotId);
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في الحذف"));
    }
  }

  Future<Map<String, dynamic>> getPlotDetails(String plotId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSpace = prefs.getDouble('space_$plotId');
      final cachedNumPlants = prefs.getInt('numPlants_$plotId');
      final cachedNumLines = prefs.getInt('numLines_$plotId');
      final cachedPlantsPerLine = prefs.getInt('plantsPerLine_$plotId');

      if (cachedSpace != null &&
          cachedNumPlants != null &&
          cachedNumLines != null &&
          cachedPlantsPerLine != null) {
        return {
          'space': cachedSpace,
          'numPlants': cachedNumPlants,
          'numLines': cachedNumLines,
          'plantsPerLine': cachedPlantsPerLine,
        };
      }

      final plotDoc = await _firestore.collection('plots').doc(plotId).get();
      if (!plotDoc.exists) {
        return {
          'space': 0.0,
          'numPlants': 0,
          'numLines': 0,
          'plantsPerLine': 0,
        };
      }

      final data = plotDoc.data()!;
      final space = (data['space'] as num?)?.toDouble() ?? 0.0;
      final numPlants = (data['numPlants'] as int?) ?? 0;
      final numLines = (data['numLines'] as int?) ?? 0;
      final plantsPerLine = (data['plantsPerLine'] as int?) ?? 0;

      await prefs.setDouble('space_$plotId', space);
      await prefs.setInt('numPlants_$plotId', numPlants);
      await prefs.setInt('numLines_$plotId', numLines);
      await prefs.setInt('plantsPerLine_$plotId', plantsPerLine);

      return {
        'space': space,
        'numPlants': numPlants,
        'numLines': numLines,
        'plantsPerLine': plantsPerLine,
      };
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في جلب تفاصيل الأرض"));
      return {
        'space': 0.0,
        'numPlants': 0,
        'numLines': 0,
        'plantsPerLine': 0,
      };
    }
  }

  Future<void> updatePlotDetails({
    required String plotId,
    required double space,
    required int numPlants,
    required int numLines,
    required int plantsPerLine,
  }) async {
    try {
      await _firestore.collection('plots').doc(plotId).update({
        'space': space,
        'numPlants': numPlants,
        'numLines': numLines,
        'plantsPerLine': plantsPerLine,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('space_$plotId', space);
      await prefs.setInt('numPlants_$plotId', numPlants);
      await prefs.setInt('numLines_$plotId', numLines);
      await prefs.setInt('plantsPerLine_$plotId', plantsPerLine);
    } catch (e) {
      emit(IrrigationErrorState(errorMessage: "فشل في تحديث تفاصيل الأرض"));
    }
  }
}
