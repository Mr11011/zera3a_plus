import '../data/inventory_product_model.dart';
import '../data/purchase_batch_model.dart';

// Base class for all states, just like in your other files.
abstract class GeneralInventoryStates {}

class GeneralInventoryInitial extends GeneralInventoryStates {}

class GeneralInventoryLoading extends GeneralInventoryStates {}

/// State for when the main list of unique products is loaded.
class ProductsLoaded extends GeneralInventoryStates {
  final List<InventoryProduct> products;

  ProductsLoaded(this.products);
}

/// State for when a specific product's details and its batches are loaded.
class ProductDetailsLoaded extends GeneralInventoryStates {
  final InventoryProduct product;
  final List<PurchaseBatch> batches;

  ProductDetailsLoaded(this.product, this.batches);
}

class GeneralInventoryError extends GeneralInventoryStates {
  final String message;

  GeneralInventoryError(this.message);
}

// States for success messages
class GeneralInventorySuccess extends GeneralInventoryStates {
  final String message;

  GeneralInventorySuccess(this.message);
}

class GeneralInventoryItemDeleted extends GeneralInventoryStates {}

class GeneralInventoryItemUpdated extends GeneralInventoryStates {}
