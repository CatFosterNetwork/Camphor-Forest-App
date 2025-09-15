// lib/pages/feedback/widgets/feedback_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/feedback_models.dart' as feedback_models;

/// Feedback list item widget
class FeedbackListItem extends ConsumerWidget {
  final feedback_models.Feedback feedback;
  final VoidCallback onTap;

  const FeedbackListItem({
    super.key,
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final userState = ref.watch(authProvider);
    final isAdmin = userState.user?.siteAdmin ?? false;

    // Background color for admin visibility indicator
    Color? backgroundColor;
    if (isAdmin) {
      if (feedback.visibility) {
        backgroundColor = Colors.green.withAlpha(25); // Visible - light green
      } else {
        backgroundColor = Colors.red.withAlpha(25); // Hidden - light red
      }
    }

    return Container(
      color: backgroundColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: _buildStatusIcon(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feedback.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '由 ${feedback.user.name} 创建于 ${_formatDate(feedback.gmtCreate)}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? const Color(0xFFA9AAAC)
                    : const Color(0xFF6B7280),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color iconColor;
    IconData iconData;

    switch (feedback.status) {
      case feedback_models.FeedbackStatus.pending:
        iconColor = Colors.green;
        iconData = Icons.circle;
        break;
      case feedback_models.FeedbackStatus.resolved:
        iconColor = Colors.purple;
        iconData = Icons.check_circle;
        break;
      case feedback_models.FeedbackStatus.rejected:
        iconColor = Colors.grey;
        iconData = Icons.cancel;
        break;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
      child: Icon(iconData, size: 12, color: Colors.white),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
