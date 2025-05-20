import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zera3a/feature/home/data/plot_model.dart';
import 'package:zera3a/feature/home/general_reports/general_reports_states.dart';

class GeneralReportsCubit extends Cubit<GeneralReportsState> {
  final FirebaseFirestore _firestore;

  GeneralReportsCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(GeneralReportsState());

  Future<void> fetchGeneralReports(List<Plot> plots, int? threshold) async {
    emit(state.copyWith(isLoading: true));
    try {
      List<String> attentionPlotName = [];
      double totalCost = 0;
      double laborTotalCost = 0;
      double irrigationTotalCost = 0;
      double inventoryTotalCost = 0;
      int plotsNeedingAttention = 0;
      threshold ??= 500000;

      for (var plot in plots) {
        final snapshot = await _firestore
            .collection('plots')
            .doc(plot.plotId)
            .collection('daily_summaries')
            .orderBy('lastUpdated', descending: true)
            .get();

        double plotTotalCost = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          plotTotalCost += (data['totalCost'] as num?)?.toDouble() ?? 0;
          laborTotalCost += (data['laborTotalCost'] as num?)?.toDouble() ?? 0;
          irrigationTotalCost +=
              (data['irrigationTotalCost'] as num?)?.toDouble() ?? 0;
          inventoryTotalCost +=
              (data['inventoryTotalCost'] as num?)?.toDouble() ?? 0;
        }

        //  if a plot's total cost exceeds a threshold, it may need attention
        if (plotTotalCost > threshold) {
          attentionPlotName.add(plot.name);
          plotsNeedingAttention++;
        }
        totalCost += plotTotalCost;
      }

      final aggregatedData = {
        'attentionPlotName': attentionPlotName,
        'totalCost': totalCost,
        'laborTotalCost': laborTotalCost,
        'irrigationTotalCost': irrigationTotalCost,
        'inventoryTotalCost': inventoryTotalCost,
        'totalPlots': plots.length,
        'plotsNeedingAttention': plotsNeedingAttention,
      };

      emit(state.copyWith(
        isLoading: false,
        plots: plots,
        aggregatedData: aggregatedData,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "فشل في تحميل التقارير العامة",
      ));
    }
  }
}
