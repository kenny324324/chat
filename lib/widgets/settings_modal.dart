import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/theme_manager.dart';
import '../core/model_manager.dart';
import '../core/app_animations.dart';

class SettingsModal {
  static void show(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "設定",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingOption(
                context, 
                icon: Icons.smart_toy_outlined, 
                title: "AI 模型設定",
                onTap: () {
                  Navigator.pop(context);
                  _showModelSelectionModal(context);
                }
              ),
              _buildSettingOption(
                context, 
                icon: Icons.text_fields_rounded, 
                title: "字體風格",
                onTap: () {
                  Navigator.pop(context);
                  _showFontSelectionModal(context);
                }
              ),
              _buildSettingOption(
                context, 
                icon: Icons.format_size, 
                title: "字體大小",
                onTap: () {
                  Navigator.pop(context);
                  _showFontSizeSelectionModal(context);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSettingOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.skinPink.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkGrey),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.darkGrey.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  static void _showModelSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "選擇 AI 模型",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildModelOption(context, AIModel.none),
              _buildModelOption(context, AIModel.gemini),
              _buildModelOption(context, AIModel.deepseek),
              _buildModelOption(context, AIModel.chatgpt, isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  static void _showFontSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
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
              _buildFontOption(context, "系統預設", "OpenHuninn"),
              _buildFontOption(context, "宇文天穹體", "AppFont"),
              _buildFontOption(context, "文青手寫體", "Handwriting"),
              _buildFontOption(context, "何某手寫體", "NaniFont"),
              _buildFontOption(context, "自動鉛筆體", "AutoPencil", isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  static void _showFontSizeSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "選擇字體大小",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildFontSizeOption(context, FontSize.small),
              _buildFontSizeOption(context, FontSize.medium),
              _buildFontSizeOption(context, FontSize.large, isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildModelOption(BuildContext context, AIModel model, {bool isLast = false}) {
    return ListenableBuilder(
      listenable: ModelManager(),
      builder: (context, _) {
        final isSelected = ModelManager().currentModel == model;
        final isDisabled = model == AIModel.chatgpt;
        
        return GestureDetector(
          onTap: isDisabled ? null : () {
            ModelManager().setModel(model);
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDisabled 
                  ? AppColors.darkGrey.withOpacity(0.1)
                  : isSelected 
                      ? AppColors.darkGrey 
                      : AppColors.skinPink.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: AppColors.darkGrey.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  model.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDisabled
                        ? AppColors.darkGrey.withOpacity(0.4)
                        : isSelected 
                            ? Colors.white 
                            : AppColors.darkGrey,
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

  static Widget _buildFontOption(BuildContext context, String name, String? fontFamily, {bool isLast = false}) {
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
              borderRadius: BorderRadius.circular(20),
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

  static Widget _buildFontSizeOption(BuildContext context, FontSize fontSize, {bool isLast = false}) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final isSelected = ThemeManager().currentFontSize == fontSize;
        
        return GestureDetector(
          onTap: () {
            ThemeManager().setFontSize(fontSize);
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.darkGrey : AppColors.skinPink.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: AppColors.darkGrey.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fontSize.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.darkGrey,
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

