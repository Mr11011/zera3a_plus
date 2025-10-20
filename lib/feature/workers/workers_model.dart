import 'package:cloud_firestore/cloud_firestore.dart';

class PlotLaborLog {
  final String docId;
  final String laborType; // 'fixed' or 'temporary'
  final String resourceId; // ID of the FixedWorker or Contractor
  final String resourceName; // Denormalized name for display

  // Use double for fractional numbers
  final double workerCount;
  final double days;

  final double costPerUnit; // The dailyRate or pricePerDay at the time of logging
  final double totalCost;
  final DateTime date;
  final String employeeId; // Who logged this
  final String plotId;

  PlotLaborLog({
    required this.docId,
    required this.laborType,
    required this.resourceId,
    required this.resourceName,
    required this.workerCount,
    required this.days,
    required this.costPerUnit,
    required this.totalCost,
    required this.date,
    required this.employeeId,
    required this.plotId,
  });

  factory PlotLaborLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlotLaborLog(
      docId: doc.id,
      laborType: data['laborType'] ?? 'temporary',
      resourceId: data['resourceId'] ?? '',
      resourceName: data['resourceName'] ?? '',
      workerCount: (data['workerCount'] as num?)?.toDouble() ?? 0.0,
      days: (data['days'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: (data['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp).toDate(),
      employeeId: data['employeeId'] ?? '',
      plotId: data['plotId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': 'labor', // Hardcoded type for the activity
      'laborType': laborType,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'workerCount': workerCount,
      'days': days,
      'costPerUnit': costPerUnit,
      'totalCost': totalCost,
      'date': Timestamp.fromDate(date),
      'employeeId': employeeId,
      'plotId': plotId,
    };
  }
}