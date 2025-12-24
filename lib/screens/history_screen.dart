import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/history_manager.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skinPink,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: HistoryManager(),
          builder: (context, _) {
            final records = HistoryManager().records;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Profile Header (as Sliver)
                SliverToBoxAdapter(
                  child: _buildProfileHeader(context),
                ),

                // 2. Content List or Empty State
                if (records.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
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
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // 底部增加 padding 避免被 tabbar 遮擋
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = records[index];
                          return _buildHistoryCard(context, record);
                        },
                        childCount: records.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：名字與頭像
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "罪孽深重的靈魂",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 認證勾勾
                      Icon(Icons.verified, color: AppColors.darkGrey, size: 20),
                      const SizedBox(width: 4),
                      // 紅點
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@soul_feeder",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGrey.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Icon(Icons.person, size: 36, color: AppColors.darkGrey),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bio
          const Text(
            "-INFJ-\n-Daily,Mood,2002-",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Follower info
          Row(
            children: [
              SizedBox(
                width: 70, 
                height: 20,
                child: Stack(
                  children: [
                     Positioned(left: 0, child: _buildTinyAvatar('assets/images/characters/chic.png', AppColors.creamYellow)),
                     Positioned(left: 12, child: _buildTinyAvatar('assets/images/characters/shiba.png', const Color(0xFFFFD180))),
                     Positioned(left: 24, child: _buildTinyAvatar('assets/images/characters/bunny.png', AppColors.powderBlue)),
                     Positioned(left: 36, child: _buildTinyAvatar('assets/images/characters/bear.png', AppColors.palePurple)),
                     Positioned(left: 48, child: _buildTinyAvatar('assets/images/characters/cat.png', Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "5 followers",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey.withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {}, // 暫時為空
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.darkGrey.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    "編輯檔案",
                    style: TextStyle(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.darkGrey.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    "分享檔案",
                    style: TextStyle(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tab Indicator (Threads / Replies)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "貼文",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 2, color: AppColors.darkGrey),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "回覆",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey.withOpacity(0.3),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.darkGrey.withOpacity(0.1)),
                  ],
                ),
              ),
            ],
          ),
          
          // Divider
          Container(height: 1, color: AppColors.darkGrey.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildTinyAvatar(String imagePath, Color color) {
    return Container(
      width: 20, 
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(imagePath, fit: BoxFit.contain),
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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.darkGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // User Name & Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "罪孽深重的靈魂",
                          style: TextStyle(
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
                  ),
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
