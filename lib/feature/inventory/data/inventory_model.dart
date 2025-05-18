import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String docId;
  final String itemId;
  final double quantityUsed;
  final double itemUnitCost;
  final double inventoryTotalCost;
  final DateTime date;
  final String employeeId;
  final String plotId;

  InventoryModel({
    required this.docId,
    required this.itemId,
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
      'quantityUsed': quantityUsed,
      'itemUnitCost': itemUnitCost,
      'inventoryTotalCost': inventoryTotalCost,
      'date': date.toUtc(),
      'employeeId': employeeId,
      'plotId': plotId,
    };
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      docId: json['docId']?.toString() ?? '',
      itemId: json['itemId'] as String,
      quantityUsed: json['quantityUsed'] as double,
      itemUnitCost: json['itemUnitCost'] as double,
      inventoryTotalCost: json['inventoryTotalCost'] as double,
      date: (json['date'] as Timestamp).toDate(),
      employeeId: json['employeeId'] as String,
      plotId: json['plotId'] as String,
    );
  }
}