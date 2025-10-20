import 'package:cloud_firestore/cloud_firestore.dart';

class FixedWorker {
  final String id;
  final String name;
  final String jobTitle;
  final double monthlySalary;
  final double dailyRate; // We will store this for plot cost calculation
  final DateTime hireDate;

  FixedWorker({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.monthlySalary,
    required this.dailyRate,
    required this.hireDate,
  });

  factory FixedWorker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FixedWorker(
      id: doc.id,
      name: data['name'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      monthlySalary: (data['monthlySalary'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (data['dailyRate'] as num?)?.toDouble() ?? 0.0,
      hireDate: (data['hireDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'jobTitle': jobTitle,
      'monthlySalary': monthlySalary,
      'dailyRate': dailyRate,
      'hireDate': Timestamp.fromDate(hireDate),
      // ownerId will be added in the cubit
    };
  }
}