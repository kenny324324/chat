import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  List<HistoryRecord> _records = [];
  bool _isInitialized = false;
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  List<HistoryRecord> get records => List.unmodifiable(_records);
  bool get isGuest => _currentUser == null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 載入本地資料 (初始狀態)
    await _loadLocal();

    // 2. 監聽登入狀態
    _authSubscription = _authService.userStream.listen(_handleAuthChange);
    
    _isInitialized = true;
    notifyListeners();
  }

  /// 處理登入狀態變更
  void _handleAuthChange(User? user) async {
    final bool wasGuest = _currentUser == null;
    final bool isNowUser = user != null;
    
    _currentUser = user;

    if (wasGuest && isNowUser) {
      // 登入事件：執行遷移並載入雲端資料
      print("User logged in: ${user.uid}. Migrating data...");
      await _migrateLocalToCloud(user.uid);
      await _loadCloud(user.uid);
    } else if (!wasGuest && !isNowUser) {
      // 登出事件：清空所有資料 (回歸全新訪客狀態)
      print("User logged out. Clearing data.");
      await clearAllLocally();
    } else if (isNowUser) {
      // 已登入狀態下的重啟：直接載入雲端
      await _loadCloud(user.uid);
    }
    // 訪客狀態維持原樣 (_loadLocal 已在 init 執行)
    
    notifyListeners();
  }

  /// 從 SharedPreferences 讀取本地資料
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _records = jsonList.map((json) => HistoryRecord.fromJson(json)).toList();
        _sortRecords();
      } catch (e) {
        print("Error loading local history: $e");
      }
    }
    notifyListeners();
  }

  /// 從 Firestore 讀取雲端資料
  Future<void> _loadCloud(String userId, {bool forceRefresh = false}) async {
    try {
      print("⚙️ 開始從 Firestore 載入，forceRefresh: $forceRefresh");
      
      // 如果 forceRefresh 為 true，強制從伺服器獲取，不使用快取
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get(forceRefresh 
              ? const GetOptions(source: Source.server) 
              : const GetOptions(source: Source.serverAndCache));

      print("📦 收到 ${snapshot.docs.length} 筆文件");
      print("📊 資料來源: ${snapshot.metadata.isFromCache ? '快取' : '伺服器'}");
      
      _records = snapshot.docs
          .map((doc) {
            final data = doc.data();
            print("   📄 ID: ${doc.id}, characters: ${(data['characters'] as List?)?.length ?? 0} 個");
            return HistoryRecord.fromJson(data);
          })
          .toList();
      
      print("✨ 解析完成，共 ${_records.length} 筆記錄");
      for (var i = 0; i < _records.length && i < 3; i++) {
        print("   記錄 $i: ${_records[i].characters.length} 個角色回答");
      }
      
      notifyListeners();
    } catch (e) {
      print("❌ Error loading cloud history: $e");
      print("❌ Stack trace: ${StackTrace.current}");
    }
  }

  /// 公開方法：重新載入資料（登入用戶從雲端，訪客從本地）
  Future<void> refresh() async {
    print("🔄 開始重新整理歷史紀錄...");
    if (_currentUser != null) {
      print("📡 強制從伺服器載入 (用戶ID: ${_currentUser!.uid})");
      await _loadCloud(_currentUser!.uid, forceRefresh: true); // 強制從伺服器刷新
      print("✅ 雲端資料載入完成，共 ${_records.length} 筆記錄");
    } else {
      print("💾 從本地載入");
      await _loadLocal();
      print("✅ 本地資料載入完成，共 ${_records.length} 筆記錄");
    }
  }

  /// 將本地資料遷移至雲端
  Future<void> _migrateLocalToCloud(String userId) async {
    if (_records.isEmpty) return;

    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('users').doc(userId).collection('history');

    for (var record in _records) {
      // 使用 record.id 作為 doc ID 避免重複
      final docRef = collectionRef.doc(record.id);
      batch.set(docRef, record.toJson());
    }

    try {
      await batch.commit();
      print("Migration successful: ${_records.length} records uploaded.");
      // 遷移成功後清空本地
      await clearAllLocally();
    } catch (e) {
      print("Migration failed: $e");
    }
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

    if (_currentUser != null) {
      // 雲端模式：直接存入 Firestore
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('history')
            .doc(record.id)
            .set(record.toJson());
        
        _records.insert(0, record); // 更新記憶體中的列表
      } catch (e) {
        print("Error saving to cloud: $e");
        // 可以在這裡做離線快取，但目前先簡單處理
      }
    } else {
      // 訪客模式：存入本地，限制 5 筆
      if (_records.length >= 5) {
        _records.removeLast(); // 移除最舊的
      }
      _records.insert(0, record);
      await _saveToPrefs();
    }
    
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    if (_currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('history')
          .doc(id)
          .delete();
    }
    
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    
    if (_currentUser == null) {
      await _saveToPrefs();
    }
  }

  /// 清空本地資料 (用於登出或遷移後)
  Future<void> clearAllLocally() async {
    _records.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    notifyListeners();
  }

  // 僅限開發測試用
  Future<void> clearAll() async {
    if (_currentUser != null) {
       // 雲端清空比較危險，暫不實作或僅清空集合
       // 這裡暫時只清空顯示
    }
    await clearAllLocally();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  void _sortRecords() {
    _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
