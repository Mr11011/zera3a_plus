import '../data/inventory_model.dart';
import '../generalInventory/data/general_inventory_model.dart';

abstract class InventoryStates {}

class InventoryInitState extends InventoryStates {}

class InventoryLoadingState extends InventoryStates {}

class InventoryLoadedState extends InventoryStates {}

class InventoryHistoryLoadedState extends InventoryStates {
  final List<InventoryModel> inventoryHistory;

  InventoryHistoryLoadedState(this.inventoryHistory);
}

class InventoryErrorState extends InventoryStates {
  final String errorMessage;

  InventoryErrorState({required this.errorMessage});
}

class InventoryDeletedState extends InventoryStates {}

class InventoryPageLoaded extends InventoryStates {
  final List<InventoryModel> history;
  final List<PlotInventory> availableItems;
  InventoryPageLoaded({required this.history, required this.availableItems});
}
