import '../data/plot_model.dart';

abstract class PlotStates {}

class PlotInitial extends PlotStates {}

class PlotLoading extends PlotStates {}

class PlotLoaded extends PlotStates {
  final List<Plot> plots;
  final List<String> cropTypes;
  PlotLoaded(this.plots, this.cropTypes);
}

class PlotError extends PlotStates {
  final String error;

  PlotError(this.error);
}
