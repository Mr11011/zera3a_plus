import '../../general_inventory/data/inventory_product_model.dart';
import '../data/inventory_model.dart';

abstract class InventoryStates {}

class InventoryInitState extends InventoryStates {}

class InventoryLoadingState extends InventoryStates {}

class InventoryErrorState extends InventoryStates {
  final String errorMessage;
  InventoryErrorState({required this.errorMessage});
}

/// State when history AND available products are loaded.
class InventoryPageLoaded extends InventoryStates {
  final List<InventoryModel> history;
  final List<InventoryProduct> availableProducts; // Changed from old item model
  InventoryPageLoaded({required this.history, required this.availableProducts});
}

// Simple states for success/delete messages
class InventoryLoadedState extends InventoryStates {} // For add success
class InventoryDeletedState extends InventoryStates {} // For delete success