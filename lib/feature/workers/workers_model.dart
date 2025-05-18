import 'package:cloud_firestore/cloud_firestore.dart';

class LaborModel {
  final String? docId; //  the document ID
  final int fixedWorkersCount;
  final int fixedWorkersCost;
  final int temporaryWorkersCount;
  final int temporaryWorkersCost;
  final int totalLaborCost;
  final DateTime date;
  final String employeeId;
  final String plotId;
  final int fixedWorkersDays;
  final int temporaryWorkersDays;

  LaborModel({
    required this.docId, // Initialize the docId field
    required this.fixedWorkersCount,
    required this.fixedWorkersCost,
    required this.temporaryWorkersCount,
    required this.temporaryWorkersCost,
    required this.totalLaborCost,
    required this.date,
    required this.employeeId,
    required this.plotId,
    required this.fixedWorkersDays,
    required this.temporaryWorkersDays,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'fixedWorkersCount': fixedWorkersCount,
      'fixedWorkersCost': fixedWorkersCost,
      'temporaryWorkersCount': temporaryWorkersCount,
      'temporaryWorkersCost': temporaryWorkersCost,
      'totalLaborCost': totalLaborCost,
      'date': date.toUtc(),
      'employeeId': employeeId,
      'plotId': plotId,
      'fixedWorkersDays': fixedWorkersDays,
      'temporaryWorkersDays': temporaryWorkersDays,
    };
  }

  // Factory to create from JSON
  factory LaborModel.fromJson(Map<String, dynamic> json) {
    return LaborModel(
      docId: json['docId']?.toString() ?? '',
      fixedWorkersCount: json['fixedWorkersCount'] as int,
      fixedWorkersCost: json['fixedWorkersCost'] as int,
      temporaryWorkersCount: json['temporaryWorkersCount'] as int,
      temporaryWorkersCost: json['temporaryWorkersCost'] as int,
      totalLaborCost: json['totalLaborCost'] as int,
      date: (json['date'] as Timestamp).toDate(),
      employeeId: json['employeeId'] as String,
      plotId: json['plotId'] as String,
      fixedWorkersDays: json['fixedWorkersDays'] as int,
      temporaryWorkersDays: json['temporaryWorkersDays'] as int,
    );
  }
}
