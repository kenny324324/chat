import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_theme.dart';
import 'core/theme_manager.dart';
import 'core/model_manager.dart';
import 'core/history_manager.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入環境變數
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file error: $e");
  }
  
  // 初始化主題管理器,載入儲存的字體設定
  await ThemeManager().initialize();
  
  // 初始化模型管理器,載入儲存的模型設定
  await ModelManager().initialize();

  // 初始化歷史紀錄
  await HistoryManager().initialize();
  
  runApp(const MyApp());
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
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
