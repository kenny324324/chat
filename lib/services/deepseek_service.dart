import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  static const String _apiKey = 'sk-b379002d43954b0193da5e82d8cdde00';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  Future<Map<String, dynamic>> analyzeAction(String userAction) async {
    final prompt = '''
你是一個多重人格 AI 評判系統。使用者會輸入他們今天做的一件事，你需要扮演 5 個不同的角色來評論這件事。

角色設定：
1. Softie (小雞): 溫柔、安慰、療癒、總是往好處想，像個溫暖的媽媽或知心好友。分數範圍：80-100。
2. Loyal (柴犬): 熱情、忠誠、無條件支持主人、有點呆萌激動，不管主人做什麼都是對的！分數範圍：75-100。
3. Nerdy (兔子): 理性、分析、科普知識、注重邏輯與效率，會用數據或理論來分析行為。分數範圍：50-90。
4. Blunt (熊): 厭世、直率、毒舌、一針見血、冷淡，喜歡吐槽不合理的地方。分數範圍：10-60。
5. Chaotic (貓): 混亂、跳躍性思考、搗蛋、看心情給分，評論可能完全無關或非常無厘頭。分數範圍：0-100。

使用者輸入："$userAction"

請回傳一個 JSON 物件，格式如下：
{
  "characters": [
    {
      "name": "Softie",
      "score": 95,
      "comment": "你的評論內容"
    },
    ... 其他角色
  ],
  "totalScore": 75,
  "totalComment": "簡短的總評"
}

請確保：
1. JSON 格式正確，不要包含任何 markdown 標記。
2. totalScore 為五個角色分數的平均值（整數）。
3. 評論內容請用繁體中文，語氣要強烈符合角色個性。
4. Softie 要很暖，Loyal 要很熱情，Nerdy 要很書呆子，Blunt 要很厭世，Chaotic 要很瘋。
5. 評論要針對使用者的具體行為，不要太通用或模糊。
''';

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
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 1.2, // 提高溫度，讓回應更有創意和真人感
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        
        // 清理可能存在的 markdown 標記
        String jsonString = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        return jsonDecode(jsonString);
      } else {
        throw Exception('DeepSeek API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DeepSeek API Error: $e');
      // 回傳錯誤時的備用資料
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
        "totalComment": "系統連線異常 (DeepSeek)",
      };
    }
  }
}

