import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Map<String, dynamic>> analyzeAction(String userAction) async {
    // 開發模式：直接回傳測試資料，避免消耗 API 額度
    // 當需要正式連線時，請將此區塊註解掉或移除
    const bool isDevMode = true;

    if (isDevMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // 模擬網路延遲
      return {
        "characters": [
          {
            "name": "Softie",
            "score": 95,
            "comment": "哇！聽起來真的很棒呢！不管結果如何，你願意嘗試就很值得鼓勵了，要給自己一個大大的擁抱喔！",
          },
          {
            "name": "Loyal",
            "score": 98,
            "comment": "汪汪！主人做什麼都是對的！我永遠支持你！你是最棒的！",
          },
          {
            "name": "Nerdy",
            "score": 82,
            "comment": "根據初步分析，這個行為符合 82% 的邏輯效益。雖然還有優化空間，但在現有資源下已是最佳解。",
          },
          {"name": "Blunt", "score": 45, "comment": "就這樣？這不是基本操作嗎？沒什麼好大驚小怪的吧。"},
          {
            "name": "Chaotic",
            "score": 88,
            "comment": "這就像是把鳳梨加在披薩上一樣，雖然怪怪的但是... 喵嗚！突然好想吃罐罐！",
          },
        ],
        "totalScore": 82,
        "totalComment": "（開發模式測試資料）整體表現不錯！",
      };
    }

    if (_model == null) await init();

    final prompt =
        '''
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
    1. JSON 格式正確。
    2. totalScore 為五個角色分數的平均值（整數）。
    3. 評論內容請用繁體中文，語氣要強烈符合角色個性。
    4. Softie 要很暖，Loyal 要很熱情，Nerdy 要很書呆子，Blunt 要很厭世，Chaotic 要很瘋。
    ''';

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
        "totalComment": "系統連線異常",
      };
    }
  }
}
