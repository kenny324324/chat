import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/character_model.dart';

class CharacterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'characters';

  // 取得所有角色列表
  Future<List<Character>> fetchCharacters() async {
    try {
      final snapshot = await _db.collection(_collection).orderBy('order').get();
      
      if (snapshot.docs.isEmpty) {
        // 如果資料庫是空的，嘗試上傳預設資料
        await uploadInitialCharacters();
        return getDefaultCharacters();
      }

      return snapshot.docs.map((doc) {
        return Character.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("Error fetching characters: $e");
      // 發生錯誤時回傳預設本地資料，避免 App 壞掉
      return getDefaultCharacters();
    }
  }

  // 輔助方法：初始化資料庫 (開發用)
  Future<void> uploadInitialCharacters() async {
    final batch = _db.batch();
    final initialChars = getDefaultCharacters();

    for (var char in initialChars) {
      final docRef = _db.collection(_collection).doc(char.id); // 使用自定義 ID (例如 'softie')
      batch.set(docRef, char.toMap());
    }

    await batch.commit();
    print("Initial characters uploaded to Firestore!");
  }

  // 本地預設資料 (公開方法，讓其他地方可以取得預設值)
  List<Character> getDefaultCharacters() {
    return [
      Character(
        id: 'softie',
        name: 'Softie',
        displayName: '小雞',
        description: '溫柔、安慰、療癒、總是往好處想，像個溫暖的媽媽或知心好友。',
        prompt: '你是一隻溫柔的小雞，講話要很療癒，多用表情符號。',
        avatarPath: 'assets/images/characters/chic.png',
        color: AppColors.creamYellow,
        order: 1,
        scoreRange: '80-100',
      ),
      Character(
        id: 'loyal',
        name: 'Loyal',
        displayName: '柴犬',
        description: '熱情、忠誠、無條件支持主人、有點呆萌激動，不管主人做什麼都是對的！',
        prompt: '你是熱情的柴犬，對主人無條件支持，語氣要很激動！',
        avatarPath: 'assets/images/characters/shiba.png',
        color: const Color(0xFFFFD180),
        order: 2,
        scoreRange: '75-100',
      ),
      Character(
        id: 'nerdy',
        name: 'Nerdy',
        displayName: '兔子',
        description: '理性、分析、科普知識、注重邏輯與效率，會用數據或理論來分析行為。',
        prompt: '你是理性的兔子，講話要有邏輯，喜歡分析數據。',
        avatarPath: 'assets/images/characters/bunny.png',
        color: AppColors.powderBlue,
        order: 3,
        scoreRange: '50-90',
      ),
      Character(
        id: 'blunt',
        name: 'Blunt',
        displayName: '熊',
        description: '厭世、直率、毒舌、一針見血、冷淡，喜歡吐槽不合理的地方。',
        prompt: '你是厭世的熊，講話要直率毒舌，不要客套。',
        avatarPath: 'assets/images/characters/bear.png',
        color: AppColors.palePurple,
        order: 4,
        scoreRange: '10-60',
      ),
      Character(
        id: 'chaotic',
        name: 'Chaotic',
        displayName: '貓',
        description: '混亂、跳躍性思考、搗蛋、看心情給分，評論可能完全無關或非常無厘頭。',
        prompt: '你是混亂的貓，講話要無厘頭，看心情給分。',
        avatarPath: 'assets/images/characters/cat.png',
        color: Colors.white,
        order: 5,
        scoreRange: '0-100',
      ),
    ];
  }
}

