import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/model_manager.dart';
import '../core/history_manager.dart';
import '../core/character_manager.dart'; // Import CharacterManager
import '../services/auth_service.dart';
import 'character_card.dart';
import '../services/gemini_service.dart';
import '../services/deepseek_service.dart';

// 與 HomeScreen 共享的平滑矩形補間
class SmoothRectTween extends RectTween {
  SmoothRectTween({super.begin, super.end});

  @override
  Rect? lerp(double t) {
    if (begin == null || end == null) {
      return super.lerp(t);
    }
    
    // 位移使用彈性回彈曲線
    final positionT = Curves.easeOutBack.transform(t);
    
    // 高度變化使用更柔和的正弦曲線
    final heightT = Curves.easeInOutSine.transform(t);
    
    // 分別插值
    final left = begin!.left + (end!.left - begin!.left) * positionT;
    final top = begin!.top + (end!.top - begin!.top) * positionT;
    final width = begin!.width + (end!.width - begin!.width) * positionT;
    final height = begin!.height + (end!.height - begin!.height) * heightT;
    
    return Rect.fromLTWH(left, top, width, height);
  }
}

RectTween createSmoothRectTween(Rect? begin, Rect? end) {
  return SmoothRectTween(begin: begin, end: end);
}

class ResultScreen extends StatefulWidget {
  final String userText;
  final HistoryRecord? historyRecord; // 如果是從歷史紀錄進入，則會有值
  final String? heroTag; // 用於 Hero 動畫的 tag

  const ResultScreen({
    super.key,
    required this.userText,
    this.historyRecord,
    this.heroTag,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  final DeepSeekService _deepseekService = DeepSeekService();
  
  // 狀態
  bool _isAnalyzing = true;
  int _averageScore = 0;
  List<Map<String, dynamic>> _characters = [];
  
  // 動畫控制器
  late AnimationController _resultAnimController;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // 設置初始佔位資料 (從 CharacterManager 載入)
    _loadInitialPlaceholders();

    if (widget.historyRecord != null) {
      _loadHistoryRecord();
      
      // 監聽 HistoryManager 的變化，以便即時更新
      HistoryManager().addListener(_onHistoryUpdated);
    } else {
      _startAnalysis();
    }
  }

  void _onHistoryUpdated() {
    // 當歷史記錄更新時，重新載入對應的記錄
    if (widget.historyRecord != null) {
      final updatedRecord = HistoryManager().records
          .firstWhere((r) => r.id == widget.historyRecord!.id, 
                      orElse: () => widget.historyRecord!);
      
      print("🔄 偵測到歷史記錄更新，重新載入 ID: ${updatedRecord.id}");
      print("   更新後角色數量: ${updatedRecord.characters.length}");
      
      final rawChars = updatedRecord.characters.map((c) => c.toJson()).toList();
      
      // 補上顏色和圖片路徑
      for (var char in rawChars) {
        _enrichCharacterData(char);
      }

      setState(() {
        _averageScore = updatedRecord.totalScore;
        _characters = rawChars;
      });
    }
  }

  @override
  void dispose() {
    if (widget.historyRecord != null) {
      HistoryManager().removeListener(_onHistoryUpdated);
    }
    _resultAnimController.dispose();
    super.dispose();
  }

  void _loadInitialPlaceholders() {
    final characters = CharacterManager().characters;
    if (characters.isNotEmpty) {
      _characters = characters.map((c) => {
        'name': c.name,
        'imagePath': c.avatarPath,
        'color': c.color,
        'score': 0,
        'comment': '',
      }).toList();
    } else {
      // Fallback: 使用寫死的預設資料，避免畫面空白
      _characters = [
        {'name': 'Softie', 'imagePath': 'assets/images/characters/chic.png', 'color': AppColors.creamYellow, 'score': 0, 'comment': ''},
        {'name': 'Loyal', 'imagePath': 'assets/images/characters/shiba.png', 'color': const Color(0xFFFFD180), 'score': 0, 'comment': ''},
        {'name': 'Nerdy', 'imagePath': 'assets/images/characters/bunny.png', 'color': AppColors.powderBlue, 'score': 0, 'comment': ''},
        {'name': 'Blunt', 'imagePath': 'assets/images/characters/bear.png', 'color': AppColors.palePurple, 'score': 0, 'comment': ''},
        {'name': 'Chaotic', 'imagePath': 'assets/images/characters/cat.png', 'color': Colors.white, 'score': 0, 'comment': ''},
      ];
    }
  }

  void _loadHistoryRecord() {
    final record = widget.historyRecord!;
    print("📖 載入歷史記錄 ID: ${record.id}");
    print("   角色回答數量: ${record.characters.length}");
    for (var char in record.characters) {
      print("   - ${char.name}: ${char.comment.substring(0, char.comment.length > 20 ? 20 : char.comment.length)}...");
    }
    
    final rawChars = record.characters.map((c) => c.toJson()).toList();
    
    // 補上顏色和圖片路徑
    for (var char in rawChars) {
      _enrichCharacterData(char);
    }

    setState(() {
      _isAnalyzing = false;
      _averageScore = record.totalScore;
      _characters = rawChars;
    });
    
    // 立即顯示動畫
    _resultAnimController.forward();
  }

  // 輔助方法：補全角色顯示資料 (動態查找 + 寫死 fallback)
  void _enrichCharacterData(Map<String, dynamic> charData) {
    final name = charData['name'];
    final character = CharacterManager().getCharacterByName(name);
    
    if (character != null) {
      charData['color'] = character.color;
      charData['imagePath'] = character.avatarPath;
    } else {
      // Fallback: 根據名字用寫死的對應
      switch (name) {
        case 'Softie':
          charData['color'] = AppColors.creamYellow;
          charData['imagePath'] = 'assets/images/characters/chic.png';
          break;
        case 'Loyal':
          charData['color'] = const Color(0xFFFFD180);
          charData['imagePath'] = 'assets/images/characters/shiba.png';
          break;
        case 'Nerdy':
          charData['color'] = AppColors.powderBlue;
          charData['imagePath'] = 'assets/images/characters/bunny.png';
          break;
        case 'Blunt':
          charData['color'] = AppColors.palePurple;
          charData['imagePath'] = 'assets/images/characters/bear.png';
          break;
        case 'Chaotic':
          charData['color'] = Colors.white;
          charData['imagePath'] = 'assets/images/characters/cat.png';
          break;
        default:
          charData['color'] = Colors.white;
          charData['imagePath'] = 'assets/images/characters/chic.png';
      }
    }
  }

  void _startAnalysis() async {
    _resultAnimController.forward(from: 0);

    // 根據選擇的模型呼叫相應的 API
    final currentModel = ModelManager().currentModel;
    Map<String, dynamic> result;

    if (currentModel == AIModel.none) {
      // 如果選擇「不使用」模型，返回預設通用留言
      await Future.delayed(const Duration(milliseconds: 800)); // 模擬思考時間
      result = {
        "characters": [
          {
            "name": "Softie",
            "score": 85,
            "comment": "不管做什麼，你都是很棒的！記得要好好照顧自己喔～",
          },
          {
            "name": "Loyal",
            "score": 95,
            "comment": "汪汪！主人做什麼都是最棒的！我永遠支持你！",
          },
          {
            "name": "Nerdy",
            "score": 70,
            "comment": "根據一般行為模式分析，這是個值得記錄的事件。",
          },
          {
            "name": "Blunt",
            "score": 50,
            "comment": "嗯，就這樣吧。沒什麼特別的感想。",
          },
          {
            "name": "Chaotic",
            "score": 88,
            "comment": "喵～今天天氣真好呢！對了你剛剛說什麼來著？",
          },
        ],
        "totalScore": 78,
        "totalComment": "預設模式：角色們的通用回應",
      };
      
      if (mounted) {
        final rawChars = List<Map<String, dynamic>>.from(result['characters']);
        
        // 去重（雖然預設模式應該不會重複，但為了一致性還是加上）
        final Map<String, Map<String, dynamic>> uniqueCharsMap = {};
        for (var char in rawChars) {
          final name = char['name'];
          if (!uniqueCharsMap.containsKey(name)) {
            uniqueCharsMap[name] = char;
          }
        }
        final deduplicatedChars = uniqueCharsMap.values.toList();
        
        // 補上顏色和圖片路徑
        for (var char in deduplicatedChars) {
          _enrichCharacterData(char);
        }

        // 儲存到歷史紀錄 (預設模式也要存)
        await HistoryManager().addRecord(
          userText: widget.userText,
          totalScore: result['totalScore'] as int,
          rawCharacters: deduplicatedChars,
        );

        setState(() {
          _isAnalyzing = false;
          _averageScore = result['totalScore'] as int;
          _characters = deduplicatedChars;
        });
      }
      return;
    }

    try {
      switch (currentModel) {
        case AIModel.gemini:
          result = await _geminiService.analyzeAction(widget.userText);
          break;
        case AIModel.deepseek:
          result = await _deepseekService.analyzeAction(widget.userText);
          break;
        case AIModel.chatgpt:
          // ChatGPT 暫不支援
          result = {
            "characters": [
              {"name": "Softie", "score": 0, "comment": "ChatGPT 暫不開放使用喔～"},
              {"name": "Nerdy", "score": 0, "comment": "系統錯誤：ChatGPT 服務尚未啟用。"},
              {"name": "Loyal", "score": 0, "comment": "汪！請選擇其他模型！"},
              {"name": "Blunt", "score": 0, "comment": "都說暫不開放了，看不懂中文？"},
              {"name": "Chaotic", "score": 0, "comment": "ChatGPT 去外太空旅遊了～"},
            ],
            "totalScore": 0,
            "totalComment": "ChatGPT 暫不開放",
          };
          break;
        case AIModel.none:
          return; // 已處理
      }
    } catch (e) {
      print('Analysis error: $e');
      result = {
        "characters": [
          {"name": "Softie", "score": 0, "comment": "哎呀，好像出了點問題呢..."},
          {"name": "Nerdy", "score": 0, "comment": "錯誤：$e"},
          {"name": "Loyal", "score": 0, "comment": "汪！不管怎樣我都支持主人！"},
          {"name": "Blunt", "score": 0, "comment": "系統炸了，還想要什麼分析？"},
          {"name": "Chaotic", "score": 0, "comment": "喵哈哈～電腦當機囉～"},
        ],
        "totalScore": 0,
        "totalComment": "系統錯誤",
      };
    }

    if (mounted) {
      final rawChars = List<Map<String, dynamic>>.from(result['characters']);
      
      // Debug: 印出原始資料
      print("=== API 回傳的角色數量: ${rawChars.length} ===");
      for (var char in rawChars) {
        print("  - ${char['name']}: ${char['score']}");
      }
      
      // 去重：確保每個角色名稱只出現一次
      final Map<String, Map<String, dynamic>> uniqueCharsMap = {};
      for (var char in rawChars) {
        final name = char['name'];
        if (!uniqueCharsMap.containsKey(name)) {
          uniqueCharsMap[name] = char;
        } else {
          print("⚠️ 警告：角色 $name 重複出現，已忽略第二次出現");
        }
      }
      final deduplicatedChars = uniqueCharsMap.values.toList();
      
      if (deduplicatedChars.length != rawChars.length) {
        print("✅ 去重完成：${rawChars.length} -> ${deduplicatedChars.length}");
      }
      
      // 補上顏色和圖片路徑
      for (var char in deduplicatedChars) {
        _enrichCharacterData(char);
      }

      // 儲存到歷史紀錄（使用去重後的資料）
      await HistoryManager().addRecord(
        userText: widget.userText,
        totalScore: result['totalScore'] as int,
        rawCharacters: deduplicatedChars,
      );

      setState(() {
        _isAnalyzing = false;
        _averageScore = result['totalScore'] as int;
        _characters = deduplicatedChars; // 使用去重後的資料
      });
      
      // 不再重新觸發動畫，避免「載入中」到「顯示內容」時卡片再次滑入
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAnalyzing, // 只有在不是分析中時才允許返回
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return; // 如果已經 pop 了就不用處理
        
        // 如果正在分析，顯示警告對話框
        if (_isAnalyzing) {
          _showInterruptWarning(context);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 頂部導航欄
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGrey),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "貼文詳情",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const Spacer(),
                  // AI 綜合評分顯示 (只在分析完成後顯示)
                  if (!_isAnalyzing)
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: _averageScore),
                      duration: const Duration(milliseconds: 1500), // 1.5秒滾動效果
                      curve: Curves.easeOutExpo, // 慢慢減速
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "$value",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  fontFamily: 'Roboto', // 確保數字顯示寬度較為固定
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // 2. 內容捲動區
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. 使用者原貼文 (Hero 動畫目標)
                    _buildUserPostCard(),
                    
                    const SizedBox(height: 24),
                    
                    // C. 角色回覆區標題
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "角色回覆 (${_characters.length})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ),

                    // D. 角色卡片列表
                    ...List.generate(_characters.length, (index) {
                      final char = _characters[index];
                      final double start = 0.4 + (index * 0.1); 
                      
                      return _StaggeredItem(
                        controller: _resultAnimController,
                        interval: Interval(start, 1.0, curve: Curves.easeOutBack),
                        child: CharacterCard(
                          imagePath: char['imagePath'] as String,
                          name: char['name'] as String,
                          comment: char['comment'] as String,
                          score: char['score'] as int,
                          themeColor: char['color'] as Color,
                          isLoading: _isAnalyzing, 
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ), // Scaffold 結束
    ); // PopScope 結束
  }

  // 使用者貼文卡片 (唯讀，Hero 目標)
  Widget _buildUserPostCard() {
    Widget cardContent = Material( // 確保 Material 包裹以避免溢出警告
      color: Colors.transparent,
      child: SingleChildScrollView( // 加上 SingleChildScrollView 以防內容過長
        physics: const NeverScrollableScrollPhysics(), // 這裡通常不需要捲動
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPink.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 加上這行，確保 Column 只佔用最小高度
            children: [
              // User Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: StreamBuilder<User?>(
                  stream: AuthService().userStream,
                  initialData: AuthService().currentUser, // 關鍵：設定初始資料！
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    // 已登入但沒設定名稱 → 「匿名」
                    // 未登入 → 「訪客」
                    final displayName = user != null
                      ? (user.displayName?.isNotEmpty == true ? user.displayName! : "匿名")
                      : "訪客";
                    final photoURL = user?.photoURL;
                    
                    return Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.skinPink.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: photoURL != null
                              ? Image.network(photoURL, fit: BoxFit.cover)
                              : const Icon(Icons.person, color: AppColors.darkGrey, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.darkGrey,
                              ),
                            ),
                            Text(
                              "剛剛",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGrey.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.more_horiz, color: AppColors.darkGrey.withOpacity(0.4)),
                      ],
                    );
                  },
                ),
              ),
              
              // Post Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // 統一 Padding, vertical 12 模擬 TextField contentPadding
                child: Text(
                  widget.userText,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              
              // Actions
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              Padding(
                padding: const EdgeInsets.all(16), // 統一為 all(16)
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.chat_bubble_outline_rounded),
                    _buildActionButton(Icons.repeat_rounded),
                    _buildActionButton(Icons.favorite_border_rounded),
                    _buildActionButton(Icons.share_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        createRectTween: createSmoothRectTween, // 加上自定義矩形補間
        child: cardContent,
      );
    }

    return cardContent;
  }
  
  Widget _buildActionButton(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, size: 26, color: AppColors.darkGrey.withOpacity(0.6)),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // 中斷警告對話框
  void _showInterruptWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.psychology_outlined, color: AppColors.darkGrey, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "角色們還在思考中...",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
              ),
            ),
          ],
        ),
        content: const Text(
          "現在返回的話，他們可能會忘記剛剛在想什麼，\n你真的要打斷他們嗎？ 🤔",
          style: TextStyle(color: AppColors.darkGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("再等等", style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // 關閉對話框
              Navigator.pop(context); // 返回上一頁
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("還是返回", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// 補回遺失的 Widget
class _StaggeredItem extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _StaggeredItem({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double value = interval.transform(controller.value);
        final double opacity = value.clamp(0.0, 1.0);
        final double slide = (1.0 - value) * 100.0;

        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
