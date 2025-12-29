import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/history_manager.dart';
import '../services/auth_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return; // 防止重複點擊
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await HistoryManager().refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ 已重新整理"),
            backgroundColor: AppColors.darkGrey,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("❌ 重新整理失敗: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ 重新整理失敗: $e"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: Column(
          children: [
            // Simple Header
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 5), // 下方 padding 再縮小 (10 -> 5)
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "動態牆",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkGrey,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // 訪客提示（僅未登入時顯示）/ 重新整理按鈕（僅登入時顯示）
                    StreamBuilder<User?>(
                      stream: AuthService().userStream,
                      initialData: AuthService().currentUser,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user == null) {
                          // 未登入：顯示訪客提示
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: AppColors.darkGrey.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "訪客模式僅保留最近 5 篇",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkGrey.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      // 已登入：顯示重新整理按鈕
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isRefreshing ? null : _handleRefresh,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkGrey.withOpacity(_isRefreshing ? 0.05 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isRefreshing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGrey),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    size: 24,
                                    color: AppColors.darkGrey,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ),
            
            // List
            Expanded(
              child: ListenableBuilder(
                listenable: HistoryManager(),
                builder: (context, _) {
                  final records = HistoryManager().records;

                  if (records.isEmpty) {
                    return Center(
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
                            "還沒有貼文喔\n快去發布第一篇動態吧",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkGrey.withOpacity(0.4),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                        stops: [0.0, 0.04, 0.95, 1.0], // 漸層範圍約 4% (適中)
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100), // Padding 30，剛好避開漸層
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _buildHistoryCard(context, record);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryRecord record) {
    // 格式化日期
    final date = "${record.timestamp.year}/${record.timestamp.month}/${record.timestamp.day}";
    final time = "${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              userText: record.userText,
              historyRecord: record,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPink.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: User Info & Score
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Avatar
                  StreamBuilder<User?>(
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.skinPink.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const ClipOval(
                              child: Icon(Icons.person, color: AppColors.darkGrey, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // User Name & Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                              Text(
                                "$date $time",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkGrey.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  // Score Badge (Pill)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6), // 淡黃色背景
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFFB300)), // 深黃色星星
                        const SizedBox(width: 4),
                        Text(
                          "${record.totalScore}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                record.userText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.darkGrey,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AppColors.darkGrey.withOpacity(0.1)),
            ),

            // 3. Footer: Character Reactions (Stacked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  // Avatars Stack
                  SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: record.characters.take(3).toList().asMap().entries.map((entry) {
                        return Align(
                          widthFactor: 0.7, // 重疊效果
                          child: _buildMiniAvatar(entry.value.name),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${record.characters.length} 則回覆",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGrey.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(String name) {
    String imagePath;
    Color color;

    switch (name) {
      case 'Softie':
        imagePath = 'assets/images/characters/chic.png';
        color = AppColors.creamYellow;
        break;
      case 'Nerdy':
        imagePath = 'assets/images/characters/bunny.png';
        color = AppColors.powderBlue;
        break;
      case 'Loyal':
        imagePath = 'assets/images/characters/shiba.png';
        color = const Color(0xFFFFD180);
        break;
      case 'Blunt':
        imagePath = 'assets/images/characters/bear.png';
        color = AppColors.palePurple;
        break;
      case 'Chaotic':
        imagePath = 'assets/images/characters/cat.png';
        color = Colors.white;
        break;
      default:
        imagePath = 'assets/images/characters/chic.png';
        color = Colors.white;
    }

    return Container(
      width: 28, // 稍微加大
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // 白色邊框加強分隔感
        boxShadow: [ // 輕微陰影讓重疊更明顯
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}