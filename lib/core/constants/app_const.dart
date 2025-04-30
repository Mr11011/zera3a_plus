import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
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


  static   Icon getCropIcon(String cropType) => switch (cropType) {
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
