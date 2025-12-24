import 'package:flutter/material.dart';
import 'character_model.dart';
import '../services/character_service.dart';

class CharacterManager extends ChangeNotifier {
  static final CharacterManager _instance = CharacterManager._internal();
  factory CharacterManager() => _instance;
  CharacterManager._internal();

  final CharacterService _service = CharacterService();
  List<Character> _characters = [];
  bool _isLoading = true;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _characters = await _service.fetchCharacters();
    } catch (e) {
      print("CharacterManager initialization error: $e");
      // 失敗時使用預設資料
      _characters = _service.getDefaultCharacters();
    }
    
    // 如果還是空的，使用預設資料
    if (_characters.isEmpty) {
      _characters = _service.getDefaultCharacters();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // 根據名字獲取角色 (用於 ResultScreen 等地方查找)
  Character? getCharacterByName(String name) {
    // 先確保有資料
    if (_characters.isEmpty) {
      _characters = _service.getDefaultCharacters();
    }
    
    try {
      return _characters.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
}
