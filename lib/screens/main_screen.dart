import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 1; // 預設在中間
  
  bool _isVisible = true;

  final List<Widget> _screens = const [
    HistoryScreen(),
    HomeScreen(),
    SettingsScreen(), // 設定頁面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false, // 防止鍵盤頂起導航列，雖然首頁有自己的處理邏輯
      body: Stack( // 使用 Stack 確保 body 延伸到全螢幕，包括 bottomNavigationBar 後方
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingTabBar(),
          ),
        ],
      ),
      // bottomNavigationBar: _buildFloatingTabBar(), // 移除 Scaffold 的 bottomNavigationBar 屬性
    );
  }

  Widget _buildFloatingTabBar() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _isVisible ? Offset.zero : const Offset(0, 2),
      curve: Curves.easeInOutCubic,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPink.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65), // 更通透的玻璃感
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8), // 邊緣高光
                    width: 1.5,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const double padding = 12.0;
                    
                    // 改為 3 個 tab
                    final double tabWidth = (totalWidth - (padding * 2)) / 3;

                    return Stack(
                      children: [
                        // 背景滑塊動畫
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 650),
                          curve: const ElasticOutCurve(1.5),
                          left: padding + (_currentIndex * tabWidth),
                          top: padding,
                          bottom: padding,
                          width: tabWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkGrey,
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                        
                        // Icons Row
                        Padding(
                          padding: const EdgeInsets.all(padding),
                          child: Row(
                            children: [
                              _buildTabItem(0, Icons.person_outline_rounded), // 回憶錄 (現在也是個人檔案)
                              _buildTabItem(1, Icons.edit_square), // 首頁 (改為寫字筆圖示)
                              _buildTabItem(2, Icons.settings), // 設定
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon) {
    final bool isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.darkGrey.withOpacity(0.4),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
