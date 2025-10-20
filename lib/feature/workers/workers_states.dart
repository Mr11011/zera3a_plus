import 'package:zera3a/feature/workers/workers_model.dart';

import '../general_workers/data/contractors.dart';
import '../general_workers/data/fixed_workers.dart';



abstract class PlotLaborState {}

class PlotLaborInitial extends PlotLaborState {}

class PlotLaborLoading extends PlotLaborState {}

class PlotLaborError extends PlotLaborState {
  final String message;
  PlotLaborError(this.message);
}

/// This state is emitted when all data for the screen is loaded
class PlotLaborPageLoaded extends PlotLaborState {
  final List<PlotLaborLog> history;
  final List<FixedWorker> availableFixedWorkers;
  final List<Contractor> availableContractors;

  PlotLaborPageLoaded({
    required this.history,
    required this.availableFixedWorkers,
    required this.availableContractors,
  });
}

// Simple states for success messages
class PlotLaborSuccess extends PlotLaborState {
  final String message;
  PlotLaborSuccess(this.message);
}
class PlotLaborDeleted extends PlotLaborState {}