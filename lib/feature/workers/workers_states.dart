import 'package:zera3a/feature/workers/workers_model.dart';

abstract class LaborStates {}

class LaborInitState extends LaborStates {}

class LaborLoadingState extends LaborStates {}

class LaborHistoryLoadedState extends LaborStates {
  final List<LaborModel> laborHistory;

  LaborHistoryLoadedState(this.laborHistory);
}

class LaborErrorState extends LaborStates {
  final String errorMessage;

  LaborErrorState({required this.errorMessage});
}

class LaborDeletedState extends LaborStates {}
