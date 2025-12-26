import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/theme_manager.dart';
import '../core/model_manager.dart';
import '../core/history_manager.dart';
import '../core/character_manager.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _loadingText = "正在喚醒 AI 人格...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // 呼吸燈效果

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 開始初始化
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. 初始化主題與字體
      await ThemeManager().initialize();
      
      // 2. 初始化模型設定
      await ModelManager().initialize();

      // 3. 初始化歷史紀錄
      await HistoryManager().initialize();

      // 4. 初始化角色 (這最花時間，因為要聯網)
      setState(() => _loadingText = "正在讀取角色設定...");
      
      // 設定一個 Timeout，如果 5 秒連不上就直接用預設值，避免卡死
      await CharacterManager().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("Character fetch timed out, using defaults.");
          return;
        },
      );

    } catch (e) {
      print("Initialization error: $e");
    } finally {
      // 無論成功失敗，都進入主畫面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 動畫
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(_animation),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowPink.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 標題
            const Text(
              "SoulFeed",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.darkGrey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            // 載入文字
            Text(
              _loadingText,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkGrey.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




