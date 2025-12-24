import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/character_manager.dart';

class DeepSeekService {
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  static const String _apiKey = 'sk-b379002d43954b0193da5e82d8cdde00';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  Future<Map<String, dynamic>> analyzeAction(String userAction) async {
    final prompt = _generatePrompt(userAction);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 1.3,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        // 處理回應編碼，確保中文顯示正常
        String responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        
        // DeepSeek 回應通常在 choices[0].message.content
        String content = data['choices'][0]['message']['content'];
        
        // 清理可能存在的 markdown 標記
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
            
        return jsonDecode(content);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('DeepSeek API Error: $e');
      // 回傳錯誤時的備用資料
      return {
        "characters": [
          {"name": "Softie", "score": 80, "comment": "DeepSeek 連線好像有點問題..."},
          {"name": "Loyal", "score": 90, "comment": "汪！DeepSeek 壞掉了嗎？"},
          {"name": "Nerdy", "score": 60, "comment": "Error: $e"},
          {"name": "Blunt", "score": 40, "comment": "爛伺服器。"},
          {"name": "Chaotic", "score": 88, "comment": "喵喵喵？"},
        ],
        "totalScore": 0,
        "totalComment": "系統連線異常",
      };
    }
  }

  String _generatePrompt(String userAction) {
    final characters = CharacterManager().characters;
    StringBuffer sb = StringBuffer();

    sb.writeln("你是一個多重人格 AI 評判系統。使用者會輸入他們今天做的一件事，你需要扮演 ${characters.length} 個不同的角色來評論這件事。");
    sb.writeln("");
    sb.writeln("角色設定：");

    if (characters.isNotEmpty) {
      // 動態生成角色設定
      for (int i = 0; i < characters.length; i++) {
        final c = characters[i];
        sb.writeln("${i + 1}. ${c.name} (${c.displayName}): ${c.description} 分數範圍：${c.scoreRange}。 Prompt 指導：${c.prompt}");
      }
    } else {
      // 備份用的寫死設定
      sb.writeln("1. Softie (小雞): 溫柔、安慰。");
      sb.writeln("2. Loyal (柴犬): 熱情、忠誠。");
      sb.writeln("3. Nerdy (兔子): 理性、分析。");
      sb.writeln("4. Blunt (熊): 厭世、直率。");
      sb.writeln("5. Chaotic (貓): 混亂、跳躍。");
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
    sb.writeln("3. 評論內容請用繁體中文，語氣要強烈符合角色個性。");
    sb.writeln("4. 評論要針對使用者的具體行為，不要太通用或模糊。");

    return sb.toString();
  }
}
