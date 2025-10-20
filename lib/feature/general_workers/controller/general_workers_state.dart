import '../data/contractors.dart';
import '../data/fixed_workers.dart';
import '../data/salary_notes.dart';

abstract class GeneralWorkersState {}

class WorkersInitial extends GeneralWorkersState {}

class WorkersLoading extends GeneralWorkersState {}

class WorkersError extends GeneralWorkersState {
  final String message;
  WorkersError(this.message);
}

/// State for the main screen, holds both lists
class WorkersLoaded extends GeneralWorkersState {
  final List<FixedWorker> fixedWorkers;
  final List<Contractor> contractors;

  WorkersLoaded({
    required this.fixedWorkers,
    required this.contractors,
  });
}

/// State for the notes screen
class NotesLoaded extends GeneralWorkersState {
  final List<SalaryNote> notes;
  NotesLoaded(this.notes);
}

/// A simple state for success messages (Add, Update, Delete)
class WorkersSuccess extends GeneralWorkersState {
  final String message;
  WorkersSuccess(this.message);
}

//GeneralWorkersItemDeleted
class GeneralWorkersItemDeleted extends GeneralWorkersState {}