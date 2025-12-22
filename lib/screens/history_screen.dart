import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "回憶錄",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "那些被審判過的日子",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),
              
              // 暫時的空狀態
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_edu_rounded,
                        size: 64,
                        color: AppColors.darkGrey.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "還沒有紀錄喔\n快去讓 AI 罵一罵吧",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.darkGrey.withOpacity(0.4),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
