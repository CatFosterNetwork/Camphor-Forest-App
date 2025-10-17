// lib/pages/feedback/feedback_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camphor_forest/core/services/toast_service.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import 'models/feedback_models.dart' as feedback_models;
import 'providers/feedback_provider.dart';
import 'widgets/feedback_reply_item.dart';
import 'widgets/feedback_reply_editor.dart';
import 'widgets/feedback_admin_controls.dart';
import 'widgets/feedback_image_gallery.dart';

/// Feedback detail screen
class FeedbackDetailScreen extends ConsumerStatefulWidget {
  final String feedbackId;

  const FeedbackDetailScreen({super.key, required this.feedbackId});

  @override
  ConsumerState<FeedbackDetailScreen> createState() =>
      _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends ConsumerState<FeedbackDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load feedback detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackId = int.tryParse(widget.feedbackId);
      if (feedbackId != null) {
        ref
            .read(feedbackDetailProvider.notifier)
            .loadFeedbackDetail(feedbackId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final feedbackId = int.tryParse(widget.feedbackId);
      if (feedbackId != null) {
        ref.read(feedbackDetailProvider.notifier).loadReplies(feedbackId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final detailState = ref.watch(feedbackDetailProvider);
    final userState = ref.watch(authProvider);

    // Listen to errors
    ref.listen(feedbackDetailProvider, (previous, current) {
      if (current.error != null && mounted) {
        ToastService.show(current.error!, backgroundColor: Colors.red);
        if (mounted) {
          ref.read(feedbackDetailProvider.notifier).clearError();
        }
      }
    });

    if (detailState.isLoading && detailState.feedback == null) {
      return ThemeAwareScaffold(
        pageType: PageType.settings,
        useBackground: false,
        appBar: ThemeAwareAppBar(title: '反馈详情'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (detailState.feedback == null) {
      return ThemeAwareScaffold(
        pageType: PageType.settings,
        useBackground: false,
        appBar: ThemeAwareAppBar(title: '反馈详情'),
        body: const Center(child: Text('反馈不存在')),
      );
    }

    final feedback = detailState.feedback!;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: ThemeAwareAppBar(title: '反馈详情'),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feedback header
                  _buildFeedbackHeader(feedback, isDarkMode),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  // Feedback content
                  _buildFeedbackContent(feedback, isDarkMode),

                  // Replies with timeline (no spacing before timeline starts)
                  if (detailState.replies.isNotEmpty) ...[
                    ...detailState.replies.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reply = entry.value;

                      return Column(
                        children: [
                          if (index == 0) _buildTimelineLine(isDarkMode),
                          FeedbackReplyItem(
                            reply: reply,
                            currentUserId: userState.user?.accountId ?? '',
                            feedbackAuthorId: feedback.user.accountId,
                          ),
                          _buildTimelineLine(isDarkMode),
                        ],
                      );
                    }),

                    Container(
                      height: 1,
                      width: double.infinity,
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                  ] else ...[
                    // If no replies, still show some spacing
                    const SizedBox(height: 16),
                  ],

                  if (detailState.isLoadingReplies)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  if (userState.user?.siteAdmin == true) ...[
                    const SizedBox(height: 16),
                    FeedbackAdminControls(
                      feedback: feedback,
                      onStatusUpdate: (status) async {
                        final feedbackId = int.tryParse(widget.feedbackId);
                        if (feedbackId != null) {
                          return await ref
                              .read(feedbackDetailProvider.notifier)
                              .updateFeedbackStatus(feedbackId, status);
                        }
                        return false;
                      },
                      onVisibilityUpdate: (visibility) async {
                        final feedbackId = int.tryParse(widget.feedbackId);
                        if (feedbackId != null) {
                          return await ref
                              .read(feedbackDetailProvider.notifier)
                              .updateFeedbackVisibility(feedbackId, visibility);
                        }
                        return false;
                      },
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Reply editor
          FeedbackReplyEditor(
            onSubmit: (content) async {
              final feedbackId = int.tryParse(widget.feedbackId);
              if (feedbackId != null) {
                final success = await ref
                    .read(feedbackDetailProvider.notifier)
                    .addReply(feedbackId, content);

                if (!success && mounted) {
                  ToastService.show('回复失败，请重试', backgroundColor: Colors.red);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackHeader(
    feedback_models.Feedback feedback,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          feedback.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),

        const SizedBox(height: 8),

        // Status and creation info
        Row(
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(feedback.status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                feedback.status.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Creation info
            Expanded(
              child: Text(
                '由 ${feedback.user.name} 创建于 ${_formatDate(feedback.gmtCreate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFFA9AAAC)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackContent(
    feedback_models.Feedback feedback,
    bool isDarkMode,
  ) {
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
            image: feedback.user.avatarUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(feedback.user.avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: feedback.user.avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),

        const SizedBox(width: 12),

        // Content
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
                  child: Text(
                    feedback.user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      // Images
                      if (feedback.images.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FeedbackImageGallery(images: feedback.images),
                      ],

                      const SizedBox(height: 12),

                      // Timestamp
                      Text(
                        _formatDate(feedback.gmtCreate),
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

  Widget _buildTimelineLine(bool isDarkMode) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.only(left: 1),
      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
    );
  }

  Color _getStatusColor(feedback_models.FeedbackStatus status) {
    switch (status) {
      case feedback_models.FeedbackStatus.pending:
        return Colors.green;
      case feedback_models.FeedbackStatus.resolved:
        return Colors.purple;
      case feedback_models.FeedbackStatus.rejected:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
