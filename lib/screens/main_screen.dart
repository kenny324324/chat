import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

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
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingTabBar(),
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
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPink.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const double padding = 12.0;
                  final double tabWidth = (totalWidth - (padding * 2)) / 3;

                  return Stack(
                    children: [
                      // 背景滑塊動畫
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 650), // 與 Modal 保持一致
                        curve: const ElasticOutCurve(1.5), // 與 Modal 保持一致的微彈感
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
                            _buildTabItem(0, Icons.history_rounded),
                            _buildTabItem(1, Icons.gavel_rounded),
                            _buildTabItem(2, Icons.person_outline_rounded),
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
