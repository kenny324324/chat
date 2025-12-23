import 'package:flutter/material.dart';

class AppAnimations {
  // 降低彈跳幅度：週期加大到 1.5，這樣衝過頭的幅度會變得非常微小，更加內斂
  static const Curve springCurve = ElasticOutCurve(1.5);
  
  // 維持您喜歡的 650ms 節奏
  static const Duration modalDuration = Duration(milliseconds: 650);

  // 通用的彈性 Modal 顯示函式
  static Future<T?> showBouncingModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color barrierColor = Colors.black26,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: modalDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Builder(builder: builder);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Sheet 內容：使用彈性曲線（會彈過頭再回來）
        final bouncyAnimation = CurvedAnimation(
          parent: animation,
          curve: springCurve,
          reverseCurve: Curves.easeInCubic,
        );

        // 底部填補區域：使用普通曲線（不彈跳，直接停在底部）
        final smoothAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            // 底部填補區域：只在開啟動畫時顯示，完成後消失
            // 當 Sheet 往上彈時，這個白色區域會遮住露出的空隙
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                // 只在動畫進行中顯示（未完成時），完成後隱藏
                // animation.status == forward 表示正在開啟
                final isOpening = animation.status == AnimationStatus.forward;
                if (!isOpening) return const SizedBox.shrink();
                
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(smoothAnimation),
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Sheet 內容：會隨動畫彈跳
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // 從下方螢幕外開始
                end: Offset.zero,          // 停在原位
              ).animate(bouncyAnimation),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
