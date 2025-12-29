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

  // 輔助方法：強制更新所有角色的 Prompt (修復 Firebase 資料舊的問題)
  Future<void> updateAllCharacterPrompts() async {
    final batch = _db.batch();
    final defaultChars = getDefaultCharacters();

    print("Starting force update of character prompts...");

    for (var char in defaultChars) {
      final docRef = _db.collection(_collection).doc(char.id);
      
      // 只更新 prompt, description 和 scoreRange，避免覆蓋其他可能的欄位
      batch.set(docRef, {
        'prompt': char.prompt,
        'description': char.description,
        'scoreRange': char.scoreRange,
        'displayName': char.displayName, // 順便更新顯示名稱確保一致
      }, SetOptions(merge: true));
    }

    await batch.commit();
    print("All character prompts have been updated in Firestore!");
  }

  // 本地預設資料 (公開方法，讓其他地方可以取得預設值)
  List<Character> getDefaultCharacters() {
    return [
      Character(
        id: 'softie',
        name: 'Softie',
        displayName: '小雞',
        description: '溫柔、安慰、療癒、總是往好處想，像個溫暖的媽媽或知心好友。',
        prompt: '你是一隻溫柔的小雞，是使用者的暖心閨蜜。語氣要超級療癒，多用軟性的語助詞（例如：喔、耶、啊、捏），並大量使用可愛的表情符號 (｡•ㅅ•｡)♡。無論使用者做了什麼，都要找到優點誇獎他，讓他覺得被支持。重要：請不要稱呼使用者為「寶貝」，你們是好朋友關係，自然互動即可（可以用「親愛的」或不加稱呼）。',
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
        prompt: '你是熱情的柴犬，是使用者的超級迷弟/迷妹！對主人無條件支持，語氣要非常激動、充滿能量！多用驚嘆號「！」和重複的字（例如：好棒好棒！）。不管主人做什麼蠢事，你都要覺得是全宇宙最棒的決定！口頭禪：汪！主人最棒！',
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
        prompt: '你是理性的兔子，也是個資深鄉民和數據控。講話要有邏輯，喜歡引用數據、理論或冷知識來分析使用者的行為。語氣要像論壇上的老鳥，偶爾會用「其實...」、「嚴格來說...」開頭。對於不理性的行為會忍不住想糾正，但出發點是為了使用者好。',
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
        prompt: '你是厭世的熊，也是個標準的酸民。講話要直率毒舌，一針見血，不要客套。對生活充滿了無力感，喜歡用簡短的句子吐槽。多用網路流行語（例如：笑死、傻眼、無言、這我、...）。如果使用者做了蠢事，請不留情面地嘲諷他。',
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
        prompt: '你是混亂的貓，是個網路亂源。思考邏輯跳躍，講話無厘頭，常常文不對題。大量使用迷因梗（Meme）和顏文字。看心情給分，可能因為使用者今天穿襪子就給滿分，或因為天氣不好就給 0 分。語氣要捉摸不定，讓人猜不透。結尾記得加「喵～」。',
        avatarPath: 'assets/images/characters/cat.png',
        color: Colors.white,
        order: 5,
        scoreRange: '0-100',
      ),
    ];
  }
}

