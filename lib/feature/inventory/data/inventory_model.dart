import 'package:cloud_firestore/cloud_firestore.dart';


class InventoryModel {
  final String docId;
  final String itemId; // Product name for display
  final String productId; // Link to the product document
  final String batchId; // Link to the specific batch document used
  final double quantityUsed;
  final double itemUnitCost;
  final double inventoryTotalCost;
  final DateTime date;
  final String employeeId;
  final String plotId;

  InventoryModel({
    required this.docId,
    required this.itemId,
    required this.productId,
    required this.batchId,
    required this.quantityUsed,
    required this.itemUnitCost,
    required this.inventoryTotalCost,
    required this.date,
    required this.employeeId,
    required this.plotId,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'productId': productId,
      'batchId': batchId,
      'quantityUsed': quantityUsed,
      'itemUnitCost': itemUnitCost,
      'inventoryTotalCost': inventoryTotalCost,
      'date': Timestamp.fromDate(date.toUtc()), // Use UTC for consistency
      'employeeId': employeeId,
      'plotId': plotId,
      'type': 'inventory_usage' // Ensure type is always set
    };
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      docId: json['docId']?.toString() ?? '',
      itemId: json['itemId'] as String? ?? '',
      productId: json['productId'] as String? ?? '', // Handle old data
      batchId: json['batchId'] as String? ?? '',     // Handle old data
      quantityUsed: (json['quantityUsed'] as num?)?.toDouble() ?? 0.0,
      itemUnitCost: (json['itemUnitCost'] as num?)?.toDouble() ?? 0.0,
      inventoryTotalCost: (json['inventoryTotalCost'] as num?)?.toDouble() ?? 0.0,
      date: (json['date'] as Timestamp).toDate(),
      employeeId: json['employeeId'] as String? ?? '',
      plotId: json['plotId'] as String? ?? '',
    );
  }
}