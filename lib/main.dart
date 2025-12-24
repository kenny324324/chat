import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'core/theme_manager.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // 引入生成的設定檔

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入環境變數
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file error: $e");
  }
  
  runApp(const AppEntry());
}

/// 應用程式入口，負責等待 Firebase 初始化
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // 使用明確的設定檔初始化 Firebase，避開原生設定檔讀取失敗的問題
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        // 1. 如果發生錯誤，顯示錯誤畫面
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "初始化失敗",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "錯誤訊息: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 2. 如果完成，進入 App
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }

        // 3. 正在初始化，顯示簡單的白色 Loading 畫面
        return const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        return MaterialApp(
          title: 'SoulFeed',
          theme: AppTheme.getTheme(ThemeManager().currentFontFamily),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
