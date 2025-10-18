import '../model/cash_flow_model.dart';

abstract class CashFlowState {}

class CashFlowInitial extends CashFlowState {}

class CashFlowLoading extends CashFlowState {}

class CashFlowError extends CashFlowState {
  final String message;
  CashFlowError(this.message);
}

class CashFlowLoaded extends CashFlowState {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;

  CashFlowLoaded({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
  });
}

// Simple state for success messages after add/update/delete
class CashFlowSuccess extends CashFlowState {}
