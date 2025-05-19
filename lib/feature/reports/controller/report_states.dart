import 'package:zera3a/feature/reports/controller/report_cubit.dart';

class ReportsState {
  final bool isLoading;
  final List<Map<String, dynamic>> dailySummaries;
  final ReportFilter filter;
  final String? errorMessage;

  ReportsState({
    this.isLoading = false,
    this.dailySummaries = const [],
    this.filter = ReportFilter.daily,
    this.errorMessage,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? dailySummaries,
    ReportFilter? filter,
    String? errorMessage,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
