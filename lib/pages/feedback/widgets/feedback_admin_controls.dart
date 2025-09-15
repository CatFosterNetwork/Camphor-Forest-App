// lib/pages/feedback/widgets/feedback_admin_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../models/feedback_models.dart' as feedback_models;

/// Feedback admin controls widget
class FeedbackAdminControls extends ConsumerStatefulWidget {
  final feedback_models.Feedback feedback;
  final Future<bool> Function(feedback_models.FeedbackStatus status)
  onStatusUpdate;
  final Future<bool> Function(bool visibility) onVisibilityUpdate;

  const FeedbackAdminControls({
    super.key,
    required this.feedback,
    required this.onStatusUpdate,
    required this.onVisibilityUpdate,
  });

  @override
  ConsumerState<FeedbackAdminControls> createState() =>
      _FeedbackAdminControlsState();
}

class _FeedbackAdminControlsState extends ConsumerState<FeedbackAdminControls> {
  bool _isLoading = false;

  Future<void> _handleStatusUpdate(
    feedback_models.FeedbackStatus status,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.onStatusUpdate(status);
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVisibilityUpdate(bool visibility) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.onVisibilityUpdate(visibility);
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '管理员操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Status control button
              if (widget.feedback.status ==
                  feedback_models.FeedbackStatus.pending) ...[
                Expanded(
                  child: _buildActionButton(
                    text: '标记为已解决',
                    color: Colors.purple,
                    onPressed: _isLoading
                        ? null
                        : () => _showConfirmDialog(
                            context,
                            '确定将此反馈设置为已完成？',
                            () => _handleStatusUpdate(
                              feedback_models.FeedbackStatus.resolved,
                            ),
                          ),
                    isLoading: _isLoading,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _buildActionButton(
                    text: '标记为已提交',
                    color: Colors.green,
                    onPressed: _isLoading
                        ? null
                        : () => _showConfirmDialog(
                            context,
                            '确定将此反馈设置为待处理？',
                            () => _handleStatusUpdate(
                              feedback_models.FeedbackStatus.pending,
                            ),
                          ),
                    isLoading: _isLoading,
                  ),
                ),
              ],

              const SizedBox(width: 12),

              // Close/Reopen button
              if (widget.feedback.status !=
                  feedback_models.FeedbackStatus.rejected) ...[
                Expanded(
                  child: _buildActionButton(
                    text: '标记为已关闭',
                    color: Colors.grey,
                    onPressed: _isLoading
                        ? null
                        : () => _showConfirmDialog(
                            context,
                            '确定将此反馈设置为已关闭？',
                            () => _handleStatusUpdate(
                              feedback_models.FeedbackStatus.rejected,
                            ),
                          ),
                    isLoading: _isLoading,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _buildActionButton(
                    text: '标记为已解决',
                    color: Colors.purple,
                    onPressed: _isLoading
                        ? null
                        : () => _showConfirmDialog(
                            context,
                            '确定将此反馈设置为已完成？',
                            () => _handleStatusUpdate(
                              feedback_models.FeedbackStatus.resolved,
                            ),
                          ),
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Visibility control button
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              text: widget.feedback.visibility ? '隐藏此反馈' : '显示此反馈',
              color: Colors.black87,
              onPressed: _isLoading
                  ? null
                  : () => _showConfirmDialog(
                      context,
                      widget.feedback.visibility
                          ? '确定要隐藏此反馈吗？隐藏后普通用户将无法看到此反馈。'
                          : '确定要显示此反馈吗？显示后所有用户都能看到此反馈。',
                      () =>
                          _handleVisibilityUpdate(!widget.feedback.visibility),
                    ),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? color.withAlpha(128) : color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
