import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../core/app_animations.dart';
import '../core/model_manager.dart';
import '../core/theme_manager.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: StreamBuilder<User?>(
              stream: AuthService().userStream,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final bool isLoggedIn = user != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // 1. User Avatar & Info (Dynamic)
                    if (isLoggedIn) 
                      UserProfileCard(user: user)
                    else 
                      _buildGuestInfo(context),

                    const SizedBox(height: 24),

                    // 2. Settings List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        // Removed Shadow
                      ),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            context,
                            icon: Icons.smart_toy_outlined,
                            title: "AI 模型設定",
                            subtitle: "選擇回應你的 AI 人格模型",
                            onTap: () => _showModelSelectionModal(context),
                          ),
                          Divider(height: 1, color: AppColors.darkGrey.withOpacity(0.05)),
                          _buildSettingItem(
                            context,
                            icon: Icons.text_fields_rounded,
                            title: "字體風格",
                            subtitle: "自定義應用程式顯示字體",
                            onTap: () => _showFontSelectionModal(context),
                          ),
                           Divider(height: 1, color: AppColors.darkGrey.withOpacity(0.05)),
                          _buildSettingItem(
                            context,
                            icon: Icons.notifications_outlined,
                            title: "通知設定",
                            onTap: () {}, // TODO
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                         // Removed Shadow
                      ),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            context,
                            icon: Icons.info_outline_rounded,
                            title: "關於 SoulFeed",
                            onTap: () {},
                          ),
                          // 只有登入時才顯示登出按鈕
                          if (isLoggedIn) ...[
                            Divider(height: 1, color: AppColors.darkGrey.withOpacity(0.05)),
                            _buildSettingItem(
                              context,
                              icon: Icons.logout_rounded,
                              title: "登出",
                              textColor: Colors.redAccent,
                              iconColor: Colors.redAccent,
                              onTap: () => _showLogoutConfirmation(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for TabBar
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }

  // 訪客狀態的使用者資訊 (點擊可登入)
  Widget _buildGuestInfo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          // Removed Shadow
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.darkGrey,
                shape: BoxShape.circle,
                // Removed Shadow
              ),
              child: const Icon(Icons.person_add_alt_1, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "訪客",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkGrey,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "點擊此處登入或註冊",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGrey.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "尚未同步雲端",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.darkGrey.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color textColor = AppColors.darkGrey,
    Color iconColor = AppColors.darkGrey,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.darkGrey.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
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
    );
  }

  void _showFontSelectionModal(BuildContext context) {
    AppAnimations.showBouncingModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
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
    );
  }

  Widget _buildModelOption(BuildContext context, AIModel model, {bool isLast = false}) {
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

  // 登出確認對話框
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // 更淡的背景
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12), // 更小的 padding
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "要走了嗎？",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10), // 更小的間距
            Text(
              "登出後，角色們會暫時找不到你之前的對話紀錄哦\n除非你重新登入，他們才會想起來 🤭",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGrey,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 更小的 padding
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10), // 更小的按鈕高度
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.darkGrey.withOpacity(0.2)),
                    ),
                  ),
                  child: const Text(
                    "再待一下",
                    style: TextStyle(color: AppColors.darkGrey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10), // 更小的按鈕高度
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "確定登出",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserProfileCard extends StatefulWidget {
  final User user;
  const UserProfileCard({super.key, required this.user});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final String downloadUrl = await StorageService().uploadUserAvatar(widget.user.uid, File(image.path));
      await widget.user.updatePhotoURL(downloadUrl);
      await widget.user.reload();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("上傳失敗: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateName() async {
    final TextEditingController controller = TextEditingController(text: widget.user.displayName);
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "設定暱稱",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                ),
                decoration: InputDecoration(
                  hintText: "輸入你的暱稱",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: AppColors.skinPink.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "取消",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.trim().isNotEmpty) {
                          try {
                            final newName = controller.text.trim();
                            print('📝 開始更新暱稱: $newName');
                            
                            await widget.user.updateDisplayName(newName);
                            print('✅ updateDisplayName 完成');
                            
                            await widget.user.reload();
                            print('✅ user.reload 完成');
                            
                            print('📌 更新後的使用者資料:');
                            print('   - UID: ${widget.user.uid}');
                            print('   - Email: ${widget.user.email}');
                            print('   - DisplayName: ${widget.user.displayName}');
                            print('   - PhotoURL: ${widget.user.photoURL}');
                            
                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ 暱稱已更新為：$newName'),
                                  backgroundColor: AppColors.darkGrey,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ 更新暱稱失敗: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ 更新失敗: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        } else {
                          print('⚠️ 暱稱不能為空');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGrey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "確定",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGrey.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          // 頭像區塊
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.skinPink.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: _isUploading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : widget.user.photoURL != null 
                        ? Image.network(widget.user.photoURL!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo_rounded, color: AppColors.darkGrey, size: 24),
                  ),
                ),
                if (!_isUploading && widget.user.photoURL != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 資訊區塊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 名稱區塊
                if (widget.user.displayName != null && widget.user.displayName!.isNotEmpty)
                  InkWell(
                    onTap: _updateName,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.user.displayName!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGrey,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded, size: 14, color: AppColors.darkGrey.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _updateName,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.skinPink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit, size: 14, color: AppColors.darkGrey),
                          SizedBox(width: 4),
                          Text(
                            "設定暱稱",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Email
                if (widget.user.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.user.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 6),
                
                // Member Badge
                Row(
                  children: [
                    Icon(Icons.verified_user, size: 12, color: AppColors.darkGrey.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      "Member",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGrey.withOpacity(0.5),
                      ),
                    ),
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
