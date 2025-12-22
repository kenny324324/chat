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
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeAction(String userAction) async {
    if (_model == null) await init();

    final prompt = '''
    你是一個多重人格 AI 評判系統。使用者會輸入他們今天做的一件事，你需要扮演 4 個不同的角色來評論這件事。

    角色設定：
    1. Softie (🐣): 溫柔、鼓勵型、正向支持。分數範圍：80-100。
    2. Blunt (🐻): 直接、毒舌、吐槽、有趣。分數範圍：30-90。
    3. Nerdy (🐰): 理性、分析、提出邏輯解釋或數據。分數範圍：50-100。
    4. Chaotic (🐱): 混亂、無厘頭、隨機亂回、天馬行空。分數範圍：1-100。

    使用者輸入："$userAction"

    請回傳一個 JSON 物件，格式如下：
    {
      "characters": [
        {
          "name": "Softie",
          "emoji": "🐣",
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
    2. totalScore 為四個角色分數的平均值（整數）。
    3. 評論內容請用繁體中文，語氣要符合角色個性。
    4. Softie 要很溫暖，Blunt 要很嗆，Nerdy 要很學術，Chaotic 要很瘋。
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      if (response.text == null) throw Exception('Empty response');
      
      // 清理可能存在的 markdown 標記 ```json ... ```
      String jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(jsonString);
    } catch (e) {
      print('Gemini API Error: $e');
      // 回傳錯誤時的備用資料
      return {
        "characters": [
          {"name": "Softie", "emoji": "🐣", "score": 80, "comment": "哎呀，連線好像有點問題，不過沒關係，你已經很棒了！"},
          {"name": "Nerdy", "emoji": "🐰", "score": 60, "comment": "系統偵測到網絡異常，建議檢查連線狀態 (Error: $e)。"},
          {"name": "Blunt", "emoji": "🐻", "score": 40, "comment": "連個網都不會連？是在哈囉？"},
          {"name": "Chaotic", "emoji": "🐱", "score": 88, "comment": "網路線被外星人拿去跳繩了嗎？"},
        ],
        "totalScore": 60,
        "totalComment": "系統連線異常"
      };
    }
  }
}

