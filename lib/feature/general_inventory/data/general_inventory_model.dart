import 'package:cloud_firestore/cloud_firestore.dart';

class PlotInventory { // Renamed class for clarity
  final String id; // The document ID from Firestore

  // Item details
  final String itemName;
  final String vendor;
  final String origin;
  final DateTime purchaseDate;
  final String category; // <-- NEW FIELD ADDED


  // Quantity tracking - This is the most important change
  final double initialQuantity; // The amount you bought (e.g., 2000 kg)
  final double currentQuantity; // The amount left (e.g., 1850.5 kg)
  final String unit; // e.g., 'kg', 'liter'

  // Cost tracking
  final double totalCost; // The cost for the initialQuantity
  final double costPerUnit; // Calculated once: totalCost / initialQuantity

  PlotInventory({
    required this.id,
    required this.itemName,
    required this.vendor,
    required this.origin,
    required this.purchaseDate,
    required this.category,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.unit,
    required this.totalCost,
    required this.costPerUnit,
  });

  // Factory to create an object from a Firestore document
  factory PlotInventory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlotInventory(
      // The ID is taken from the document itself, not from the data map
      id: doc.id,
      itemName: data['itemName'] ?? '',
      vendor: data['vendor'] ?? '',
      origin: data['origin'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      initialQuantity: (data['initialQuantity'] as num).toDouble(),
      currentQuantity: (data['currentQuantity'] as num).toDouble(),
      unit: data['unit'] ?? '',
      totalCost: (data['totalCost'] as num).toDouble(),
      costPerUnit: (data['costPerUnit'] as num).toDouble(),
    );
  }

  // Method to convert our object into a map for Firestore
  // Note: The 'id' is not included here because it's the document name, not a field.
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'vendor': vendor,
      'origin': origin,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'category': category,
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'unit': unit,
      'totalCost': totalCost,
      'costPerUnit': costPerUnit,
    };
  }
}
