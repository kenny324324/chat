import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/character_manager.dart';
import '../core/history_manager.dart'; // Import HistoryRecord

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;

  // 初始化
  Future<void> init() async {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 1.2, // 提高溫度，讓回應更有創意和真人感
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeAction(String userAction, {List<HistoryRecord> history = const []}) async {
    if (_model == null) await init();

    final prompt = _generatePrompt(userAction, history);

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null) throw Exception('Empty response');

      // 清理可能存在的 markdown 標記 ```json ... ```
      String jsonString = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonString);
    } catch (e) {
      print('Gemini API Error: $e');
      // 回傳錯誤時的備用資料 (這裡也可以優化為動態生成，但暫時保留寫死以防萬一)
      return {
        "characters": [
          {
            "name": "Softie",
            "score": 80,
            "comment": "哎呀，連線好像有點問題，不過沒關係，你已經很棒了！",
          },
          {"name": "Loyal", "score": 90, "comment": "汪！雖然連線怪怪的，但我還是最喜歡主人了！"},
          {
            "name": "Nerdy",
            "score": 60,
            "comment": "系統偵測到網絡異常，建議檢查連線狀態 (Error: $e)。",
          },
          {"name": "Blunt", "score": 40, "comment": "連個網都不會連？是在哈囉？"},
          {"name": "Chaotic", "score": 88, "comment": "網路線被外星人拿去跳繩了嗎？"},
        ],
        "totalScore": 71,
        "totalComment": "系統連線異常",
      };
    }
  }

  Future<String> replyToCharacter({
    required String characterName,
    required String characterPrompt,
    required String originalEvent,
    required String initialComment,
    required List<ChatMessage> threadHistory,
    required String newUserInput,
  }) async {
    if (_model == null) await init();

    StringBuffer sb = StringBuffer();
    sb.writeln("你現在需要扮演一個特定的角色來回應使用者。");
    sb.writeln("角色設定：$characterPrompt");
    sb.writeln("");
    sb.writeln("背景資訊：");
    sb.writeln("使用者原本的行為：$originalEvent");
    sb.writeln("你最初的評論：$initialComment");
    sb.writeln("");
    sb.writeln("對話紀錄：");
    for (var msg in threadHistory) {
      sb.writeln("${msg.role == 'user' ? '使用者' : '你'}: ${msg.content}");
    }
    sb.writeln("使用者最新回覆：$newUserInput");
    sb.writeln("");
    sb.writeln("請根據你的角色設定，用簡短口語（像在傳訊息）回應使用者。不要重複之前的內容。");
    sb.writeln("直接輸出回應內容即可，不需要JSON格式。");

    try {
      final content = [Content.text(sb.toString())];
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? "（沈默）";
    } catch (e) {
      print("Reply Error: $e");
      return "（連線不穩中...）";
    }
  }

  String _generatePrompt(String userAction, List<HistoryRecord> history) {
    final characters = CharacterManager().characters;
    StringBuffer sb = StringBuffer();

    sb.writeln("你是一個多重人格 AI 評判系統。使用者會輸入他們今天做的一件事，你需要扮演 ${characters.length} 個不同的角色來評論這件事。");
    sb.writeln("");
    
    // --- 新增：短期記憶區塊 ---
    if (history.isNotEmpty) {
      sb.writeln("[使用者近期歷史紀錄]");
      sb.writeln("以下是使用者最近的 ${history.length} 筆活動紀錄。請自行判斷哪些與本次事件相關。");
      sb.writeln("如果有相關（例如連續幾天都晚睡、或是重複抱怨工作、前後行為反差大），請務必在評論中提及，表現出你記得這些事；如果無關則可忽略。");
      for (var record in history) {
        // 格式： 2023-10-27: 不想上班 (總分: 20)
        final dateStr = "${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}";
        sb.writeln("- $dateStr: ${record.userText} (總分: ${record.totalScore})");
      }
      sb.writeln("");
      sb.writeln("[結束歷史紀錄]");
      sb.writeln("");
    }
    // -----------------------

    sb.writeln("重要規則：");
    sb.writeln("1. 請使用繁體中文（台灣用語）。");
    sb.writeln("2. 嚴禁出現翻譯腔或過度客套的書面語。");
    sb.writeln("3. 請大量使用台灣網路流行語（例如：笑死、傻眼、真假、這我、急了、破防）。");
    sb.writeln("4. 語氣要像在通訊軟體（LINE/IG）上聊天，可以使用「～」、「！」或半形表情符號。");
    sb.writeln("");
    sb.writeln("角色設定：");

    if (characters.isNotEmpty) {
      // 動態生成角色設定
      for (int i = 0; i < characters.length; i++) {
        final c = characters[i];
        sb.writeln("${i + 1}. ${c.name} (${c.displayName}): ${c.description} 分數範圍：${c.scoreRange}。 Prompt 指導：${c.prompt}");
      }
    } else {
      // 備份用的寫死設定 (以防萬一)
      sb.writeln("1. Softie (小雞): 溫柔、安慰、療癒。分數範圍：80-100。");
      sb.writeln("2. Loyal (柴犬): 熱情、忠誠、無條件支持主人。分數範圍：75-100。");
      sb.writeln("3. Nerdy (兔子): 理性、分析、科普知識。分數範圍：50-90。");
      sb.writeln("4. Blunt (熊): 厭世、直率、毒舌。分數範圍：10-60。");
      sb.writeln("5. Chaotic (貓): 混亂、跳躍性思考。分數範圍：0-100。");
    }

    sb.writeln("");
    sb.writeln('使用者輸入："$userAction"');
    sb.writeln("");
    sb.writeln("請回傳一個 JSON 物件，格式如下：");
    sb.writeln("{");
    sb.writeln('  "characters": [');
    sb.writeln('    {');
    sb.writeln('      "name": "角色英文名稱 (必須與上述設定完全一致)",');
    sb.writeln('      "score": 95,');
    sb.writeln('      "comment": "你的評論內容"');
    sb.writeln('    },');
    sb.writeln('    ... 其他角色');
    sb.writeln('  ],');
    sb.writeln('  "totalScore": 75,');
    sb.writeln('  "totalComment": "簡短的總評"');
    sb.writeln("}");
    sb.writeln("");
    sb.writeln("請確保：");
    sb.writeln("1. JSON 格式正確。");
    sb.writeln("2. totalScore 為五個角色分數的平均值（整數）。");
    sb.writeln("3. 評論內容請用繁體中文，語氣要強烈符合角色個性，且必須口語化。");
    sb.writeln("4. 評論要針對使用者的具體行為，一針見血，不要講空泛的大道理。");

    return sb.toString();
  }
}
