import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_theme.dart';
import '../core/app_animations.dart';
import 'character_card.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  
  // 狀態
  bool _showResult = false;
  bool _isAnalyzing = false;
  
  // 資料
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  // 開啟輸入 Modal (整合彈跳動畫)
  void _showInputModal() {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => _InputModal(
        controller: _controller,
        onSubmit: () {
          Navigator.pop(context);
          _startAnalysis();
        },
      ),
    );
  }

  void _startAnalysis() async {
    if (_controller.text.isEmpty) return;
    
    // 1. 切換狀態
    setState(() {
      _showResult = true;
      _isAnalyzing = true;
      _averageScore = 0;
      
      // 佔位資料
      _characters = [
        {'name': 'Softie', 'emoji': '🐣', 'color': AppColors.creamYellow, 'score': 0, 'comment': ''},
        {'name': 'Nerdy', 'emoji': '🐰', 'color': AppColors.powderBlue, 'score': 0, 'comment': ''},
        {'name': 'Blunt', 'emoji': '🐻', 'color': AppColors.palePurple, 'score': 0, 'comment': ''},
        {'name': 'Chaotic', 'emoji': '🐱', 'color': Colors.white, 'score': 0, 'comment': ''},
      ];
    });

    _resultAnimController.forward(from: 0);

    // 2. 呼叫 API
    final result = await _geminiService.analyzeAction(_controller.text);

    if (mounted) {
      final rawChars = List<Map<String, dynamic>>.from(result['characters']);
      
      // 補上顏色
      for (var char in rawChars) {
        switch (char['name']) {
          case 'Softie': char['color'] = AppColors.creamYellow; break;
          case 'Nerdy': char['color'] = AppColors.powderBlue; break;
          case 'Blunt': char['color'] = AppColors.palePurple; break;
          case 'Chaotic': char['color'] = Colors.white; break;
          default: char['color'] = Colors.white;
        }
      }

      setState(() {
        _isAnalyzing = false;
        _averageScore = result['totalScore'] as int;
        _characters = rawChars;
      });
    }
  }

  void _reset() {
    setState(() {
      _showResult = false;
      _controller.clear();
      _characters = [];
      _averageScore = 0;
      _isAnalyzing = false;
    });
    _resultAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: _showResult ? _buildResultView() : _buildHomeView(),
      ),
    );
  }

  // === 新版首頁：沉浸式舞台 ===
  Widget _buildHomeView() {
    return Stack(
      key: const ValueKey('HomeView'),
      children: [
        // 1. 角落偷看的角色 (Peeking Characters)
        Positioned(
          top: -30,
          left: 20,
          child: _PeekingCharacter(
            emoji: "🐣", 
            angle: 0.2, 
            delay: 0,
            color: AppColors.creamYellow,
          ),
        ),
        Positioned(
          top: 100,
          right: -40,
          child: _PeekingCharacter(
            emoji: "🐰", 
            angle: -0.3, 
            delay: 1000,
            color: AppColors.powderBlue,
          ),
        ),
        Positioned(
          bottom: 150,
          left: -40,
          child: _PeekingCharacter(
            emoji: "🐻", 
            angle: 0.3, 
            delay: 500,
            color: AppColors.palePurple,
          ),
        ),
        Positioned(
          bottom: -30,
          right: 40,
          child: _PeekingCharacter(
            emoji: "🐱", 
            angle: -0.1, 
            delay: 1500,
            color: Colors.white,
          ),
        ),

        // 2. 中央互動區
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Today's Story",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGrey.withOpacity(0.3),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              
              // 呼吸的按鈕
              GestureDetector(
                onTap: _showInputModal,
                child: _PulsingButton(),
              ),
              
              const SizedBox(height: 32),
              Text(
                "點擊告解",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === 結果視圖 ===
  Widget _buildResultView() {
    return Stack(
      key: const ValueKey('ResultView'),
      children: [
        // 背景按鈕
        if (!_isAnalyzing)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _resultAnimController,
                  curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
                ),
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, color: AppColors.darkGrey),
                  label: const Text(
                    "再來一次",
                    style: TextStyle(color: AppColors.darkGrey, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // 主要內容
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 總分 (大標題)
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _resultAnimController,
                    curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isAnalyzing ? "?" : _averageScore.toString(),
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                          height: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.darkGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isAnalyzing ? "評判中..." : "今日得分",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // 角色卡片列表
              ...List.generate(_characters.length, (index) {
                final char = _characters[index];
                final double start = 0.3 + (index * 0.15); 
                
                return _StaggeredItem(
                  controller: _resultAnimController,
                  interval: Interval(start, 1.0, curve: Curves.easeOutBack),
                  child: CharacterCard(
                    emoji: char['emoji'] as String,
                    name: char['name'] as String,
                    comment: char['comment'] as String,
                    score: char['score'] as int,
                    themeColor: char['color'] as Color,
                    isLoading: _isAnalyzing, 
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// === 新增元件：偷看的角色 ===
class _PeekingCharacter extends StatefulWidget {
  final String emoji;
  final double angle;
  final int delay;
  final Color color;

  const _PeekingCharacter({
    required this.emoji,
    required this.angle,
    required this.delay,
    required this.color,
  });

  @override
  State<_PeekingCharacter> createState() => _PeekingCharacterState();
}

class _PeekingCharacterState extends State<_PeekingCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 輕微的探頭動作
        final move = math.sin(_controller.value * math.pi) * 10;
        return Transform.translate(
          offset: Offset(move * (widget.angle > 0 ? 1 : -1), move),
          child: Transform.rotate(
            angle: widget.angle,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// === 新增元件：呼吸按鈕 ===
class _PulsingButton extends StatefulWidget {
  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPink,
                blurRadius: 20 + (_controller.value * 20),
                spreadRadius: 5 + (_controller.value * 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            size: 40,
            color: AppColors.darkGrey,
          ),
        );
      },
    );
  }
}

// === 新增元件：輸入 Modal ===
class _InputModal extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _InputModal({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 使用 margin 讓 modal 看起來是懸浮的，縮小邊距 (16 -> 8)
      margin: const EdgeInsets.all(8),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, // 避開鍵盤並多留空間
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // 加大圓角 (32 -> 40)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "告解時間",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.darkGrey),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            style: const TextStyle(fontSize: 18, color: AppColors.darkGrey),
            decoration: const InputDecoration(
              hintText: "今天發生了什麼...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("接受審判", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// 輔助 StaggeredItem
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
