import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIModel {
  none('不使用', 'none'),
  gemini('Gemini', 'gemini'),
  deepseek('DeepSeek', 'deepseek'),
  chatgpt('ChatGPT', 'chatgpt');

  final String displayName;
  final String value;
  const AIModel(this.displayName, this.value);

  static AIModel fromString(String value) {
    return AIModel.values.firstWhere(
      (model) => model.value == value,
      orElse: () => AIModel.none,
    );
  }
}

class ModelManager extends ChangeNotifier {
  // Singleton
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  static const String _modelKey = 'selected_ai_model';
  AIModel _currentModel = AIModel.none;
  bool _isInitialized = false;

  AIModel get currentModel => _currentModel;
  bool get isInitialized => _isInitialized;

  // 初始化時從本地儲存讀取模型設定
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_modelKey);
    
    if (savedModel != null) {
      _currentModel = AIModel.fromString(savedModel);
    } else {
      _currentModel = AIModel.none;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  // 設定模型並儲存到本地
  Future<void> setModel(AIModel model) async {
    if (_currentModel != model) {
      _currentModel = model;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelKey, model.value);
      
      notifyListeners();
    }
  }

  // 取得當前模型的可用狀態
  bool get isModelAvailable {
    switch (_currentModel) {
      case AIModel.none:
        return false;
      case AIModel.gemini:
        return true;
      case AIModel.deepseek:
        return true;
      case AIModel.chatgpt:
        return false; // ChatGPT 暫不開放
    }
  }

  // 取得模型不可用的原因
  String? get unavailableReason {
    if (_currentModel == AIModel.chatgpt) {
      return 'ChatGPT 服務暫不開放';
    }
    return null;
  }
}

