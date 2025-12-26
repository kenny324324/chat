import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/theme_manager.dart';
import '../core/model_manager.dart';
import '../core/app_animations.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: Column(
          children: [
            // 標題
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "設定",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 50, width: double.infinity, color: Colors.red, child: Center(child: Text("DEBUG: 若看到我表示檔案正確", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),

            // 設定項目
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 帳號區塊 (加入錯誤邊框以便除錯)
                  _buildAccountSection(context),
                  const SizedBox(height: 20),

                  _buildSettingOption(
                    context,
                    icon: Icons.smart_toy_outlined,
                    title: "AI 模型設定",
                    onTap: () => _showModelSelectionModal(context),
                  ),
                  _buildSettingOption(
                    context,
                    icon: Icons.text_fields_rounded,
                    title: "字體風格",
                    onTap: () => _showFontSelectionModal(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        // Debug 資訊：印出目前狀態
        print("Auth Stream State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, Data: ${snapshot.data}");

        if (snapshot.hasError) {
           return Container(
             padding: const EdgeInsets.all(16),
             color: Colors.red.withOpacity(0.1),
             child: Text("Auth Error: ${snapshot.error}"),
           );
        }

        // 只要連線狀態不是 waiting，或者有資料 (即使是 null)，就顯示 UI
        // 注意：Stream 的初始狀態可能是 waiting，這時候應該顯示預設 UI (訪客)
        
        final user = snapshot.data;
        if (user != null) {
          return _buildLoggedInView(context, user);
        } else {
          return _buildGuestView(context);
        }
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPink.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("登入 / 註冊", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("永久保存您的紀錄", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
            BoxShadow(
              color: AppColors.shadowPink.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
         ],
       ),
       child: Column(
         children: [
           Row(
             children: [
               CircleAvatar(
                 backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                 backgroundColor: AppColors.skinPink,
                 radius: 24,
                 child: user.photoURL == null ? Text(user.displayName?[0].toUpperCase() ?? "U", style: const TextStyle(fontWeight: FontWeight.bold)) : null,
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(user.displayName ?? "使用者", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGrey)),
                     if (user.email != null)
                      Text(user.email!, style: TextStyle(color: AppColors.darkGrey.withOpacity(0.5), fontSize: 12)),
                   ],
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton(
               onPressed: () async {
                  await AuthService().signOut();
               },
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.red,
                 side: BorderSide(color: Colors.red.withOpacity(0.5)),
                 padding: const EdgeInsets.symmetric(vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text("登出"),
             ),
           )
         ],
       ),
    );
  }

  Widget _buildSettingOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // 減少垂直 padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPink.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkGrey, size: 28), // 移除背景容器
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.darkGrey.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  static void _showModelSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
    );
  }

  static void _showFontSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
    );
  }

  static Widget _buildModelOption(BuildContext context, AIModel model,
      {bool isLast = false}) {
    return ListenableBuilder(
        listenable: ModelManager(),
        builder: (context, _) {
          final isSelected = ModelManager().currentModel == model;
          final isDisabled = model == AIModel.chatgpt;

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
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
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.darkGrey.withOpacity(0.1)),
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
        });
  }

  static Widget _buildFontOption(BuildContext context, String name, String? fontFamily,
      {bool isLast = false}) {
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
                color: isSelected
                    ? AppColors.darkGrey
                    : AppColors.skinPink.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.darkGrey.withOpacity(0.1)),
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
        });
  }
}
