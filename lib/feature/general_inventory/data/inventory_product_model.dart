import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryProduct {
  final String id; // The document ID from Firestore
  final String itemName;
  final String category;
  final String unit;
  final double totalStock; // Sum of all current quantities in all batches
  final double totalInitialStock; // Sum of all initial quantities in all batches

  InventoryProduct({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.totalStock,
    required this.totalInitialStock,

  });

  factory InventoryProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryProduct(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? '',
      unit: data['unit'] ?? '',
      totalStock: (data['totalStock'] as num?)?.toDouble() ?? 0.0,
      totalInitialStock: (data['totalInitialStock'] as num?)?.toDouble() ?? 0.0,

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'category': category,
      'unit': unit,
      'totalStock': totalStock,
      'totalInitialStock': totalInitialStock,
    };
  }
}