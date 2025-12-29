import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/history_manager.dart'; // Import for ChatMessage

class CharacterCard extends StatefulWidget {
  final String imagePath;
  final String name;
  final String comment;
  final int score;
  final Color themeColor;
  final bool isLoading;
  final List<ChatMessage> replies;
  final Function(String)? onReply; // 回覆回調

  const CharacterCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.comment,
    required this.score,
    required this.themeColor,
    this.isLoading = false,
    this.replies = const [],
    this.onReply,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  bool _isExpanded = false; // 是否展開評論區
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || widget.onReply == null) return;

    // 先清除輸入框並隱藏鍵盤 (優化體驗)
    _replyController.clear();
    // FocusScope.of(context).unfocus(); // 如果希望送出後收起鍵盤可取消註解

    setState(() {
      _isSending = true;
    });

    try {
      // 呼叫父層處理 (UI 更新由父層 setState 驅動)
      await widget.onReply!(text);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          // 主要內容區
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側頭像
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.themeColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),

              // 右側內容區
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 頂部資訊列 (名字 + 分數)
                    Row(
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!widget.isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${widget.score}",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.themeColor,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 留言內容
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: widget.isLoading
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: widget.themeColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "正在回覆...",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
                              widget.comment,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: AppColors.darkGrey,
                              ),
                            ),
                    ),

                    const SizedBox(height: 8),

                    // 底部互動按鈕
                    if (!widget.isLoading)
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 22,
                            color: AppColors.darkGrey.withOpacity(0.7),
                          ),
                          const SizedBox(width: 20),

                          // 回覆按鈕 (控制展開)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 21,
                                  color: _isExpanded
                                      ? AppColors.darkGrey
                                      : AppColors.darkGrey.withOpacity(0.7),
                                ),
                                if (widget.replies.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    "${widget.replies.length}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _isExpanded
                                          ? AppColors.darkGrey
                                          : AppColors.darkGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),
                          Icon(
                            Icons.share_outlined,
                            size: 21,
                            color: AppColors.darkGrey.withOpacity(0.7),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // 展開的對話/評論區
          if (_isExpanded && !widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 歷史對話串
                  if (widget.replies.isNotEmpty || _isSending)
                    Column(
                      children: [
                        ...widget.replies.map((msg) {
                          final isUser = msg.role == 'user';

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                              right: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 頭像
                                Container(
                                  width: 42,
                                  height: 42,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppColors.darkGrey
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: isUser
                                        ? null
                                        : Border.all(
                                            color: widget.themeColor
                                                .withOpacity(0.5),
                                            width: 1,
                                          ),
                                  ),
                                  child: ClipOval(
                                    child: isUser
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : Image.asset(
                                            widget.imagePath,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                // 內容
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 名字與時間
                                      Row(
                                        children: [
                                          Text(
                                            isUser ? "你" : widget.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.darkGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatTime(msg.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.content,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: AppColors.darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // AI 思考中指示器
                        if (_isSending)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                              right: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 頭像
                                Container(
                                  width: 42,
                                  height: 42,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.themeColor.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      widget.imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // 純文字提示
                                Container(
                                  height: 42, // 與頭像等高，讓文字垂直居中
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "${widget.name} 正在回覆...",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // 輸入框（膠囊樣式）
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 6,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  decoration: InputDecoration(
                                    hintText: "回覆 ${widget.name}",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: (_) => _handleSend(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (!_isSending)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.darkGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: _handleSend,
                                    padding: EdgeInsets.zero,
                                    iconSize: 16,
                                  ),
                                ),
                            ],
                          ),
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
