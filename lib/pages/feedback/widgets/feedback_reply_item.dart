// lib/pages/feedback/widgets/feedback_reply_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../models/feedback_models.dart';

/// Feedback reply item widget
class FeedbackReplyItem extends ConsumerWidget {
  final FeedbackReply reply;
  final String currentUserId;
  final String feedbackAuthorId;

  const FeedbackReplyItem({
    super.key,
    required this.reply,
    required this.currentUserId,
    required this.feedbackAuthorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    // Handle status change replies
    if (reply.isStatusChange) {
      return _buildStatusChangeReply(isDarkMode);
    }

    return _buildNormalReply(isDarkMode);
  }

  Widget _buildStatusChangeReply(bool isDarkMode) {
    final statusChange = reply.statusChangeType;
    if (statusChange == null) return const SizedBox.shrink();

    Color statusColor;
    String statusText;

    switch (statusChange) {
      case FeedbackStatus.resolved:
        statusColor = Colors.purple;
        statusText = '已解决';
        break;
      case FeedbackStatus.rejected:
        statusColor = Colors.grey;
        statusText = '已关闭';
        break;
      case FeedbackStatus.pending:
        statusColor = Colors.green;
        statusText = '已提交';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(left: 48, bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFFA9AAAC) : Colors.grey.shade600,
          ),
          children: [
            TextSpan(
              text:
                  '${reply.author.name} 于 ${_formatDate(reply.gmtCreate)} 将此问题标记为 ',
            ),
            TextSpan(
              text: statusText,
              style: TextStyle(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalReply(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
            image: reply.author.avatarUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(reply.author.avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: reply.author.avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),

        const SizedBox(width: 12),

        // Reply content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: isDarkMode
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withAlpha(26),
                            ),
                          )
                        : Border(
                            bottom: BorderSide(color: Colors.grey.shade400),
                          ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        reply.author.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildUserBadge(isDarkMode),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Timestamp
                      Text(
                        _formatDate(reply.gmtCreate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? const Color(0xFFA9AAAC)
                              : const Color(0xFFA6A6A6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserBadge(bool isDarkMode) {
    String badgeText;
    Color badgeColor;

    if (reply.author.siteAdmin) {
      badgeText = '管理员';
      badgeColor = Colors.red;
    } else if (reply.author.accountId == currentUserId) {
      badgeText = '我';
      badgeColor = Colors.blue;
    } else if (reply.author.accountId == feedbackAuthorId) {
      badgeText = '作者';
      badgeColor = Colors.green;
    } else {
      badgeText = '用户';
      badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.white.withAlpha(26) : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
