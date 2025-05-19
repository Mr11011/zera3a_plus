// class ReportsModel {
//   final double totalCost;
//   final double laborTotalCost;
//   final int laborTotalDays;
//   final int laborTotalWorkers;
//   final int irrigationDays;
//   final double irrigationHours;
//   final double irrigationTotalCost;
//   final double inventoryTotalCost;
//   final double inventoryTotalQuantity;
//   final Map<String, int> counts;
//   final DateTime date;
//
//   ReportsModel({
//     required this.totalCost,
//     required this.laborTotalCost,
//     required this.laborTotalDays,
//     required this.laborTotalWorkers,
//     required this.irrigationDays,
//     required this.irrigationHours,
//     required this.irrigationTotalCost,
//     required this.inventoryTotalCost,
//     required this.inventoryTotalQuantity,
//     required this.counts,
//     required this.date,
//   });
//
//   factory ReportsModel.fromJson(Map<String, dynamic> json, String dateStr) {
//     return ReportsModel(
//       totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
//       laborTotalCost: (json['laborTotalCost'] as num?)?.toDouble() ?? 0.0,
//       laborTotalDays: (json['laborTotalDays'] as int?) ?? 0,
//       laborTotalWorkers: (json['laborTotalWorkers'] as int?) ?? 0,
//       irrigationDays: (json['irrigationDays'] as int?) ?? 0,
//       irrigationHours: (json['irrigationHours'] as num?)?.toDouble() ?? 0.0,
//       irrigationTotalCost: (json['irrigationTotalCost'] as num?)?.toDouble() ?? 0.0,
//       inventoryTotalCost: (json['inventoryTotalCost'] as num?)?.toDouble() ?? 0.0,
//       inventoryTotalQuantity: (json['inventoryTotalQuantity'] as num?)?.toDouble() ?? 0.0,
//       counts: (json['counts'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {'labor': 0, 'irrigation': 0, 'inventory': 0},
//       date: DateTime.parse(dateStr),
//     );
//   }
// }