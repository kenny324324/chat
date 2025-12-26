import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import 'result_screen.dart';
import '../services/auth_service.dart';

// 自定義 Hero 矩形補間，讓高度變化更平滑
class SmoothRectTween extends RectTween {
  SmoothRectTween({super.begin, super.end});

  @override
  Rect? lerp(double t) {
    if (begin == null || end == null) {
      return super.lerp(t);
    }

    // 位移使用彈性回彈曲線，有輕微的超出和回彈效果
    final positionT = Curves.easeOutBack.transform(t);

    // 高度變化使用更柔和的曲線，讓高度更從容地展開/收縮
    final heightT = Curves.easeInOutSine.transform(t);

    // 分別插值 X/Y 位置、寬度和高度
    final left = begin!.left + (end!.left - begin!.left) * positionT;
    final top = begin!.top + (end!.top - begin!.top) * positionT;
    final width = begin!.width + (end!.width - begin!.width) * positionT;
    final height =
        begin!.height + (end!.height - begin!.height) * heightT; // 高度用更柔和的曲線

    return Rect.fromLTWH(left, top, width, height);
  }
}

// Hero 矩形補間構建器
RectTween createSmoothRectTween(Rect? begin, Rect? end) {
  return SmoothRectTween(begin: begin, end: end);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  // 狀態 (已將分析狀態移至 ResultScreen)
  // bool _showResult = false; // 已移除

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnalysis() async {
    if (_controller.text.trim().isEmpty) return;

    // 1. 先收起鍵盤
    FocusScope.of(context).unfocus();

    // 2. 關鍵優化：稍微等待鍵盤動畫開始，避免與頁面轉場搶資源導致卡頓
    // 通常鍵盤動畫約 250ms，這裡等待 100ms 讓 UI 執行緒喘口氣
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 跳轉到結果頁面 (使用自訂轉場或標準轉場，這裡使用標準轉場配合 Hero)
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600), // 加快到 600ms
        reverseTransitionDuration: const Duration(milliseconds: 450), // 返回也加快
        pageBuilder: (context, animation, secondaryAnimation) =>
            ResultScreen(
              userText: _controller.text,
              heroTag: 'post_card_hero', // 從首頁進入時啟用 Hero
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 進入時：快速淡入
          var fadeIn = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
          );

          // 返回時：快速淡入（secondaryAnimation 需要反轉）
          // 當上層頁面關閉時，secondaryAnimation 從 1 -> 0
          // 我們希望 HomeScreen 從 0 -> 1，所以用 reverse
          var fadeInOnReturn = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ReverseAnimation(secondaryAnimation),
              curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
            ),
          );

          return FadeTransition(
            opacity: fadeIn,
            child: FadeTransition(opacity: fadeInOnReturn, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      resizeToAvoidBottomInset: true,
      body: _buildHomeView(),
    );
  }

  // === 新版首頁：社群風格 ===
  Widget _buildHomeView() {
    return Scaffold(
      backgroundColor: AppColors.skinPink, // 保持背景色，但在上面疊加層次
      body: SafeArea(
        child: Column(
          children: [
            // 1. 頂部導航欄 (Custom App Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "SoulFeed",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkGrey,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // 使用者名稱膠囊（僅登入時顯示）
                  StreamBuilder<User?>(
                    stream: AuthService().userStream,
                    initialData: AuthService().currentUser, // 設定初始資料
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      
                      // 未登入時顯示佔位（保持佈局）
                      if (user == null) {
                        return const SizedBox(width: 1); // 極小佔位，不可見但保持佈局
                      }
                      
                      final hasName = user.displayName?.isNotEmpty == true;
                      
                      return GestureDetector(
                        onTap: () => _showEditNameDialog(context, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: hasName ? AppColors.darkGrey : AppColors.darkGrey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.darkGrey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasName ? Icons.person : Icons.edit,
                                size: 14,
                                color: hasName ? Colors.white : AppColors.darkGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasName ? user.displayName! : "設定名稱",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: hasName ? Colors.white : AppColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // 2. 角色動態列 (Stories Rail)
                    SizedBox(
                      height: 115,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildStoryAvatar(
                            "Softie",
                            "assets/images/characters/chic.png",
                            [const Color(0xFFFFD54F), const Color(0xFFFFECB3)],
                          ),
                          _buildStoryAvatar(
                            "Nerdy",
                            "assets/images/characters/bunny.png",
                            [const Color(0xFF64B5F6), const Color(0xFFBBDEFB)],
                          ),
                          _buildStoryAvatar(
                            "Loyal",
                            "assets/images/characters/shiba.png",
                            [const Color(0xFFFFB74D), const Color(0xFFFFE0B2)],
                          ),
                          _buildStoryAvatar(
                            "Blunt",
                            "assets/images/characters/bear.png",
                            [const Color(0xFF9575CD), const Color(0xFFD1C4E9)],
                          ),
                          _buildStoryAvatar(
                            "Chaotic",
                            "assets/images/characters/cat.png",
                            [const Color(0xFFE0E0E0), const Color(0xFFF5F5F5)],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. 發文卡片區 (Create Post Card - Hero Source)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hero(
                        tag: 'post_card_hero',
                        createRectTween: createSmoothRectTween, // 加上自定義矩形補間
                        // 移除 flightShuttleBuilder，使用 Flutter 預設的 Hero 行為
                        // 這樣可以確保飛行中的 Widget 與實際 Widget 完全一致，不會有跳動
                        child: Material(
                          color: Colors.transparent,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.8,
                                ), // 與 ResultScreen 一致
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowPink.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 卡片頭部：使用者資訊
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      0,
                                    ), // 與 ResultScreen 完全一致
                                    child: StreamBuilder<User?>(
                                      stream: AuthService().userStream,
                                      initialData: AuthService().currentUser, // 設定初始資料
                                      builder: (context, snapshot) {
                                        final user = snapshot.data;
                                        // 已登入但沒設定名稱 → 「匿名」
                                        // 未登入 → 「訪客」
                                        final displayName = user != null
                                          ? (user.displayName?.isNotEmpty == true ? user.displayName! : "匿名")
                                          : "訪客";
                                        // 暫時強制使用預設頭貼
                                        // final photoURL = user?.photoURL;
                                        
                                        return Row(
                                          children: [
                                            Container(
                                              width: 42, // 統一為 42
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: AppColors.skinPink.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const ClipOval(
                                                child: Icon(
                                                  Icons.person,
                                                  color: AppColors.darkGrey,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16, // 統一為 16
                                                    color: AppColors.darkGrey,
                                                  ),
                                                ),
                                                Text(
                                                  "撰寫新貼文...",
                                                  style: TextStyle(
                                                    fontSize: 12, // 統一為 12
                                                    color: AppColors.darkGrey
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),

                                  // 輸入框
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ), // 與 ResultScreen 完全一致
                                    child: TextField(
                                      controller: _controller,
                                      maxLines: 6,
                                      minLines: 3,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.darkGrey,
                                        height: 1.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "今天發生了什麼事？\n和角色們分享吧...",
                                        hintStyle: TextStyle(
                                          color: AppColors.darkGrey.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets
                                            .zero, // 移除內部 padding，外部已有
                                        filled: true,
                                        fillColor: Colors.transparent,
                                      ),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),

                                  // 分隔線
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.withOpacity(0.1),
                                  ),

                                  // 底部工具列與發送按鈕
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // 裝飾性按鈕
                                        _buildActionButton(
                                          Icons.image_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionButton(
                                          Icons.location_on_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionButton(
                                          Icons.sentiment_satisfied_rounded,
                                        ),

                                        const Spacer(),

                                        // 發送按鈕
                                        AnimatedScale(
                                          scale:
                                              _controller.text.trim().isNotEmpty
                                              ? 1.0
                                              : 0.95,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: FilledButton.icon(
                                            onPressed:
                                                _controller.text.trim().isEmpty
                                                ? null
                                                : _startAnalysis,
                                            icon: const Icon(
                                              Icons.send_rounded,
                                              size: 18,
                                            ),
                                            label: const Text("發佈"),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.darkGrey,
                                              disabledBackgroundColor: AppColors
                                                  .darkGrey
                                                  .withOpacity(0.2),
                                              foregroundColor: Colors.white,
                                              disabledForegroundColor: Colors
                                                  .white
                                                  .withOpacity(0.5),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ], // 外層 Column children 閉合
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 裝飾性的小按鈕
  Widget _buildActionButton(IconData icon) {
    return IconButton(
      onPressed: () {}, // 暫無功能，但也加上點擊效果
      icon: Icon(
        icon,
        size: 26,
        color: AppColors.darkGrey.withOpacity(0.6),
      ), // 放大 Icon
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero, // 減少內距
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 縮小點擊區域佔位
      ),
    );
  }

  Widget _buildStoryAvatar(
    String name,
    String imagePath,
    List<Color> gradientColors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5), // 調整邊框寬度
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 漸層邊框
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              // 移除 padding 以消除白邊
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                width: 64, // 圖片顯示區域
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  // 顯示編輯名稱對話框
  void _showEditNameDialog(BuildContext context, User user) {
    final controller = TextEditingController(text: user.displayName ?? '');
    
    showDialog(
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                ),
                decoration: InputDecoration(
                  hintText: "輸入你的暱稱",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: AppColors.skinPink.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.darkGrey.withOpacity(0.2), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.darkGrey.withOpacity(0.2), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.darkGrey, width: 2),
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
                        final newName = controller.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⚠️ 暱稱不能為空"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        try {
                          print("📝 開始更新暱稱: $newName");
                          await user.updateDisplayName(newName);
                          await user.reload();
                          print("✅ 暱稱更新成功: $newName");
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ 暱稱已更新為：$newName"),
                                backgroundColor: AppColors.darkGrey,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          print("❌ 暱稱更新失敗: $e");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ 更新失敗: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
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
}
