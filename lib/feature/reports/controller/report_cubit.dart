import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zera3a/feature/reports/controller/report_states.dart';

enum ReportFilter { daily, weekly, monthly }


class ReportsCubit extends Cubit<ReportsState> {
  final FirebaseFirestore _firestore;

  ReportsCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(ReportsState());

  Future<void> fetchReports(String plotId, ReportFilter filter) async {
    emit(state.copyWith(isLoading: true));
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;
      switch (filter) {
        case ReportFilter.daily:
          startDate = endDate.subtract(const Duration(days: 1));
          break;
        case ReportFilter.weekly:
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case ReportFilter.monthly:
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          break;
      }

      final start = DateFormat('yyyy-MM-dd').format(startDate);
      final end = DateFormat('yyyy-MM-dd').format(endDate);
      final snapshot = await _firestore
          .collection('plots')
          .doc(plotId)
          .collection('daily_summaries')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
          .where(FieldPath.documentId, isLessThanOrEqualTo: end)
          .orderBy(FieldPath.documentId)
          .get();

      final summaries = snapshot.docs.map((doc) {
        return {
          'date': doc.id,
          ...doc.data(),
        };
      }).toList();

      emit(state.copyWith(
          dailySummaries: summaries, filter: filter, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: "فشل في تحميل التقارير: $e", isLoading: false));
    }
  }
}
