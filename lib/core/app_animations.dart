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
        // 使用自定義的彈性曲線
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: springCurve,
          reverseCurve: Curves.easeInCubic, // 收起時不需要彈性，快速收起即可
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // 從下方螢幕外開始
            end: Offset.zero,          // 停在原位
          ).animate(curvedAnimation),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: child, // 這裡的 child 就是我們傳入的 Modal 內容
            ),
          ),
        );
      },
    );
  }
}
