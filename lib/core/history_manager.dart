import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CharacterResult {
  final String name;
  final int score;
  final String comment;

  CharacterResult({
    required this.name,
    required this.score,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'comment': comment,
  };

  factory CharacterResult.fromJson(Map<String, dynamic> json) {
    return CharacterResult(
      name: json['name'],
      score: json['score'],
      comment: json['comment'],
    );
  }
}

class HistoryRecord {
  final String id;
  final DateTime timestamp;
  final String userText;
  final int totalScore;
  final List<CharacterResult> characters;

  HistoryRecord({
    required this.id,
    required this.timestamp,
    required this.userText,
    required this.totalScore,
    required this.characters,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'userText': userText,
    'totalScore': totalScore,
    'characters': characters.map((c) => c.toJson()).toList(),
  };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      userText: json['userText'],
      totalScore: json['totalScore'],
      characters: (json['characters'] as List)
          .map((c) => CharacterResult.fromJson(c))
          .toList(),
    );
  }
}

class HistoryManager extends ChangeNotifier {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;
  HistoryManager._internal();

  static const String _historyKey = 'analysis_history';
  List<HistoryRecord> _records = [];
  bool _isInitialized = false;

  List<HistoryRecord> get records => List.unmodifiable(_records);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _records = jsonList.map((json) => HistoryRecord.fromJson(json)).toList();
        // 按時間倒序排列
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (e) {
        print("Error loading history: $e");
      }
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> addRecord({
    required String userText,
    required int totalScore,
    required List<Map<String, dynamic>> rawCharacters,
  }) async {
    final record = HistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      userText: userText,
      totalScore: totalScore,
      characters: rawCharacters.map((c) => CharacterResult(
        name: c['name'],
        score: c['score'],
        comment: c['comment'],
      )).toList(),
    );

    _records.insert(0, record); // 加到最前面
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearAll() async {
    _records.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }
}

