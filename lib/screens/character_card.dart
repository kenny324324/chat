import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CharacterCard extends StatelessWidget {
  final String imagePath; // 改為圖片路徑
  final String name;
  final String comment;
  final int score;
  final Color themeColor;
  final bool isLoading;

  const CharacterCard({
    super.key,
    required this.imagePath, // 
    required this.name,
    required this.comment,
    required this.score,
    required this.themeColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // 移除底部 margin，改成列表的 padding 或分隔線
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // 調整內距，像一般留言列表
      decoration: BoxDecoration(
        // 移除背景色和邊框，或是只保留底部分隔線
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 頂部對齊
        children: [
          // 左側頭像
          Container(
            width: 42, 
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 右側內容區
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 頂部資訊列 (名字 + 分數)
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 分數小標籤
                    if (!isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.darkGrey, // 改成深色背景，確保對比度
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$score",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeColor, // 字體使用角色顏色，在深色背景上會很清楚
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // 留言內容或打字動畫
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: _TypingIndicator(color: AppColors.darkGrey.withOpacity(0.4)),
                        )
                      : Text(
                          comment,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.darkGrey,
                          ),
                        ),
                ),
                
                const SizedBox(height: 8),
                
                // 底部互動按鈕 (裝飾用，增加社群感)
                if (!isLoading)
                  Row(
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 16),
                      Icon(Icons.share_outlined, size: 16, color: Colors.grey[400]),
                    ],
                  ),
              ],
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
