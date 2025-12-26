import 'package:flutter/material.dart';

class Character {
  final String id;
  final String name; // 英文代號 (Softie)
  final String displayName; // 中文顯示名稱
  final String description; // 個性描述
  final String prompt; // AI Prompt
  final String avatarType; // 'asset' or 'network'
  final String avatarPath;
  final Color color;
  final int order;
  final String scoreRange;

  Character({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.prompt,
    this.avatarType = 'asset',
    required this.avatarPath,
    required this.color,
    this.order = 99,
    this.scoreRange = '0-100',
  });

  factory Character.fromMap(Map<String, dynamic> data, String id) {
    // 處理顏色字串 (例如 "0xFFFFEBD1" -> Color)
    Color parseColor(String colorStr) {
      try {
        return Color(int.parse(colorStr));
      } catch (e) {
        return Colors.white;
      }
    }

    return Character(
      id: id,
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      description: data['description'] ?? '',
      prompt: data['prompt'] ?? '',
      avatarType: data['avatarType'] ?? 'asset',
      avatarPath: data['avatarPath'] ?? '',
      color: parseColor(data['color'] ?? '0xFFFFFFFF'),
      order: data['order'] ?? 99,
      scoreRange: data['scoreRange'] ?? '0-100',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'prompt': prompt,
      'avatarType': avatarType,
      'avatarPath': avatarPath,
      'color': '0x${color.value.toRadixString(16).toUpperCase()}',
      'order': order,
      'scoreRange': scoreRange,
    };
  }
}



