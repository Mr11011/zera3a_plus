abstract class IrrigationStates {}

class IrrigationInitState extends IrrigationStates {}

class IrrigationLoadingState extends IrrigationStates {}

class IrrigationLoadedState extends IrrigationStates {}

class IrrigationHistoryLoadedState extends IrrigationStates {
  final List<Map<String, dynamic>> irrigationHistory;

  IrrigationHistoryLoadedState(this.irrigationHistory);
}

class IrrigationErrorState extends IrrigationStates {
  final String errorMessage;

  IrrigationErrorState({required this.errorMessage});
}

class IrrigationDeletedState extends IrrigationStates {}

class IrrigationConstantsLoadedState extends IrrigationStates {
  final Map<String, dynamic> constants;
  IrrigationConstantsLoadedState(this.constants);
}

class IrrigationUnitCostUpdatedState extends IrrigationStates {}

