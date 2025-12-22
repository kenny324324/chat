import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CharacterCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String comment;
  final int score;
  final Color themeColor;
  final bool isLoading; // 新增狀態

  const CharacterCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.comment,
    required this.score,
    required this.themeColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 頭像
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 名字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // 分數顯示 (載入中顯示 ...)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading 
                  ? SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: themeColor,
                      )
                    )
                  : Text(
                      "$score",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.darkGrey,
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 留言內容或打字動畫
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? _TypingIndicator(color: AppColors.darkGrey.withOpacity(0.4))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// 簡單的三點跳動動畫
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = (_controller.value + index * 0.2) % 1.0;
              final double y = 4 * -((t - 0.5).abs() - 0.5); // 波浪計算
              
              return Transform.translate(
                offset: Offset(0, y * 5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: widget.color.withOpacity(0.6 + (y < 0 ? 0.4 : 0)),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
