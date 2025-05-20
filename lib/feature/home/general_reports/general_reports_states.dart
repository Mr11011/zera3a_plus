import '../data/plot_model.dart';

class GeneralReportsState {
  final bool isLoading;
  final List<Plot> plots;
  final Map<String, dynamic> aggregatedData;
  final String? errorMessage;

  GeneralReportsState({
    this.isLoading = false,
    this.plots = const [],
    this.aggregatedData = const {},
    this.errorMessage,
  });

  GeneralReportsState copyWith({
    bool? isLoading,
    List<Plot>? plots,
    Map<String, dynamic>? aggregatedData,
    String? errorMessage,
  }) {
    return GeneralReportsState(
      isLoading: isLoading ?? this.isLoading,
      plots: plots ?? this.plots,
      aggregatedData: aggregatedData ?? this.aggregatedData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
