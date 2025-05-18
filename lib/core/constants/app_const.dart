import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../di.dart';
import '../utils/colors.dart';

class AppConstant {
  static Color getCropColor(String cropType) {
    switch (cropType) {
      case 'عنب':
        return Colors.redAccent;
      case 'قمح':
        return AppColor.medBrown;
      case 'ذرة':
        return Colors.orange;
      case 'أخري':
        return Colors.green;
      case 'خوخ':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  static Icon getCropIcon(String cropType) => switch (cropType) {
        'قمح' => Icon(FluentIcons.leaf_three_16_regular,
            color: AppConstant.getCropColor(cropType)),
        'ذرة' => Icon(Icons.grass, color: AppConstant.getCropColor(cropType)),
        'عنب' =>
          Icon(Icons.grain_rounded, color: AppConstant.getCropColor(cropType)),
        'أخري' => Icon(Icons.eco, color: AppConstant.getCropColor(cropType)),
        'خوخ' => Icon(FluentIcons.leaf_one_16_filled,
            color: AppConstant.getCropColor(cropType)),
        _ => Icon(FluentIcons.earth_leaf_16_regular,
            color: AppConstant.getCropColor(cropType)),
      };
}

// Fetch the user's role from Firestore
Future<String> fetchUserRole(String userRole) async {
  try {
    final user = sl<FirebaseAuth>().currentUser;
    if (user != null) {
      final userDoc =
          await sl<FirebaseFirestore>().collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userRole = userDoc['role'] ?? 'supervisor';
      }
    }
  } catch (e) {
    debugPrint("Error fetching user role: $e");
  }
  return 'supervisor'; // fallback
}



String convertToArabicNumbers(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}