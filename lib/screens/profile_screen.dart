import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/theme_manager.dart';
import '../core/app_animations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                "我的檔案",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 32),
              
              // 用戶頭像
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.person, size: 50, color: AppColors.darkGrey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "罪孽深重的靈魂",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 設定選項列表
              _buildSettingItem(
                context,
                icon: Icons.text_fields_rounded, 
                title: "字體風格",
                onTap: () => _showFontSelectionModal(context),
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications_outlined, 
                title: "通知設定",
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.privacy_tip_outlined, 
                title: "隱私權政策",
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.info_outline, 
                title: "關於 App",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPink.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkGrey),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.darkGrey.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  void _showFontSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "選擇字體",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 20),
            _buildFontOption(context, "系統預設", null),
            _buildFontOption(context, "宇文天穹體", "AppFont"),
            _buildFontOption(context, "粉圓體", "OpenHuninn", isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOption(BuildContext context, String name, String? fontFamily, {bool isLast = false}) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final isSelected = ThemeManager().currentFontFamily == fontFamily;
        
        return GestureDetector(
          onTap: () {
            ThemeManager().setFontFamily(fontFamily);
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.darkGrey : AppColors.skinPink.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20), // 增加圓角 (16 -> 20)
              border: isSelected ? null : Border.all(color: AppColors.darkGrey.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.darkGrey,
                    // 強制設為空字串以觸發 fallback，避免繼承全域字體
                    fontFamily: fontFamily ?? '', 
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white)
              ],
            ),
          ),
        );
      }
    );
  }
}
