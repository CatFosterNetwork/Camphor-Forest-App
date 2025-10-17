// lib/pages/index/widgets/todo_edit_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import '../../../core/widgets/theme_aware_dialog.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

/// 待办事项编辑模态框
/// 增强版本，提升易用性和用户体验
class TodoEditModal extends ConsumerStatefulWidget {
  final TodoItem? initialTodo;
  final bool darkMode;
  final Color themeColor;

  const TodoEditModal({
    super.key,
    this.initialTodo,
    required this.darkMode,
    required this.themeColor,
  });

  @override
  ConsumerState<TodoEditModal> createState() => _TodoEditModalState();
}

class _TodoEditModalState extends ConsumerState<TodoEditModal>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TodoItem _currentTodo;
  late bool _isEditing;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDeleting = false; // 删除状态
  bool _isSaving = false; // 保存状态
  String? _errorMessage; // 错误信息

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialTodo != null;

    _currentTodo =
        widget.initialTodo ??
        TodoItem(
          id: 0,
          title: '',
          due: null, // 默认无截止时间，让用户主动选择
          important: false,
          finished: false,
        );

    _titleController = TextEditingController(text: _currentTodo.title);

    // 初始化动画
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    // 启动动画
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.darkMode;
    final themeColor = widget.themeColor;

    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final surfaceColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : Colors.grey.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 100, 16, 40),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDarkMode ? 76 : 25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题栏
                      _buildHeader(themeColor, textColor, subtitleColor),

                      // 内容区域
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题输入
                              _buildTitleInput(
                                textColor,
                                subtitleColor,
                                borderColor,
                                themeColor,
                              ),

                              const SizedBox(height: 24),

                              // 截止时间选择
                              _buildDateTimeSection(
                                textColor,
                                subtitleColor,
                                surfaceColor,
                                borderColor,
                                themeColor,
                              ),

                              const SizedBox(height: 24),

                              // 重要性和其他选项
                              _buildOptionsSection(
                                textColor,
                                subtitleColor,
                                surfaceColor,
                                themeColor,
                              ),

                              const SizedBox(height: 32),

                              // 操作按钮
                              _buildActionButtons(
                                context,
                                themeColor,
                                textColor,
                                backgroundColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color themeColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withAlpha(26), themeColor.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditing ? Icons.edit_outlined : Icons.add_task_rounded,
              color: themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? '编辑待办事项' : '新增待办事项',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  _isEditing ? '修改你的计划' : '记录重要的事情',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closeModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  color: subtitleColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(
    Color textColor,
    Color subtitleColor,
    Color borderColor,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '待办事项',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: themeColor.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: '描述你要做的事情...',
              hintStyle: TextStyle(
                color: subtitleColor.withAlpha(178),
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: themeColor,
                  size: 20,
                ),
              ),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              _currentTodo = _currentTodo.copyWith(title: value);
              // 清除错误信息
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
        ),

        // 错误提示
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeSection(
    Color textColor,
    Color subtitleColor,
    Color surfaceColor,
    Color borderColor,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '截止时间',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // 快速选择按钮
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickDateButton(
                '今天',
                DateTime.now().add(const Duration(hours: 2)),
                themeColor,
                subtitleColor,
              ),
              const SizedBox(width: 8),
              _buildQuickDateButton(
                '明天',
                DateTime.now().add(const Duration(days: 1, hours: 9)),
                themeColor,
                subtitleColor,
              ),
              const SizedBox(width: 8),
              _buildQuickDateButton(
                '下周',
                DateTime.now().add(const Duration(days: 7, hours: 9)),
                themeColor,
                subtitleColor,
              ),
              const SizedBox(width: 8),
              _buildQuickDateButton(
                '自定义',
                null,
                themeColor,
                subtitleColor,
                isCustom: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 当前选择的时间显示
        if (_currentTodo.due != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withAlpha(51)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: themeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '截止时间',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                      Text(
                        _formatDetailedDateTime(_currentTodo.due!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentTodo = _currentTodo.copyWith(due: null);
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.clear_rounded,
                        color: subtitleColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickDateButton(
    String label,
    DateTime? dateTime,
    Color themeColor,
    Color subtitleColor, {
    bool isCustom = false,
  }) {
    final isSelected =
        !isCustom &&
        _currentTodo.due != null &&
        dateTime != null &&
        _isSameDay(_currentTodo.due!, dateTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isCustom) {
            _showCustomDateTimePicker();
          } else {
            setState(() {
              _currentTodo = _currentTodo.copyWith(due: dateTime);
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : themeColor.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? themeColor : themeColor.withAlpha(76),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustom)
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: isSelected ? Colors.white : themeColor,
                ),
              if (isCustom) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection(
    Color textColor,
    Color subtitleColor,
    Color surfaceColor,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选项',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // 重要性开关
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentTodo.important
                      ? Colors.orange.withAlpha(26)
                      : Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentTodo.important
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _currentTodo.important ? Colors.orange : subtitleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标记为重要',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '重要的事项会优先显示',
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _currentTodo.important,
                onChanged: (value) {
                  setState(() {
                    _currentTodo = _currentTodo.copyWith(important: value);
                  });
                },
                activeColor: Colors.orange,
                activeTrackColor: Colors.orange.withAlpha(76),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color themeColor,
    Color textColor,
    Color backgroundColor,
  ) {
    return Column(
      children: [
        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTodo,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaving ? Colors.grey : themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? '保存中...' : '添加中...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditing
                            ? Icons.save_rounded
                            : Icons.add_task_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? '保存修改' : '添加待办',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // 次要操作按钮
        Row(
          children: [
            // 取消按钮
            Expanded(
              child: TextButton(
                onPressed: _closeModal,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withAlpha(178),
                  ),
                ),
              ),
            ),

            // 删除按钮（仅编辑模式）
            if (_isEditing) ...[
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: _isDeleting ? null : _showDeleteConfirmation,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDeleting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '删除中...',
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '删除',
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showCustomDateTimePicker() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _currentTodo.due ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)), // 允许选择昨天开始，提高灵活性
      lastDate: now.add(const Duration(days: 365 * 2)), // 扩大到2年范围
      helpText: '选择截止日期',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.themeColor,
              surface: widget.darkMode ? const Color(0xFF2A2A2A) : Colors.white,
              onSurface: widget.darkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _currentTodo.due ?? now.add(const Duration(hours: 1)),
        ),
        helpText: '选择截止时间',
        cancelText: '取消',
        confirmText: '确定',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: widget.themeColor,
                surface: widget.darkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                onSurface: widget.darkMode ? Colors.white : Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          _currentTodo = _currentTodo.copyWith(due: dateTime);
        });
      }
    }
  }

  void _showDeleteConfirmation() async {
    final shouldDelete = await ThemeAwareDialog.showConfirmDialog(
      context,
      title: '确认删除',
      message: '确定要删除这个待办事项吗？此操作无法撤销。',
      negativeText: '取消',
      positiveText: '删除',
    );

    if (shouldDelete) {
      _deleteTodo();
    }
  }

  Future<void> _deleteTodo() async {
    if (_isDeleting) return; // 防止重复点击

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(todoProvider.notifier).deleteTodo(_currentTodo.id);
      if (mounted) {
        // 添加轻微的触觉反馈
        HapticFeedback.lightImpact();

        // 删除成功后关闭模态框
        _closeModal();

        ToastService.show(
          '删除成功',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        // 添加错误触觉反馈
        HapticFeedback.heavyImpact();

        ToastService.show(
          '删除失败：$e',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _saveTodo() async {
    if (_isSaving) return; // 防止重复点击

    // 验证标题
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入待办事项';
      });
      return;
    }

    // 验证时间（仅对新添加的待办事项）
    if (!_isEditing && _currentTodo.due == null) {
      setState(() {
        _errorMessage = '请选择截止时间';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedTodo = _currentTodo.copyWith(
      title: _titleController.text.trim(),
    );

    try {
      if (_isEditing) {
        await ref
            .read(todoProvider.notifier)
            .modifyTodo(updatedTodo.id, updatedTodo);
      } else {
        await ref
            .read(todoProvider.notifier)
            .addTodo(updatedTodo.title, updatedTodo.due, updatedTodo.important);
      }

      if (mounted) {
        // 添加轻微的触觉反馈
        HapticFeedback.lightImpact();

        _closeModal();
        ToastService.show(
          _isEditing ? '修改成功' : '添加成功',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        // 添加错误触觉反馈
        HapticFeedback.heavyImpact();

        ToastService.show(
          '操作失败：$e',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _closeModal() {
    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (targetDate == today) {
      dateStr = '今天';
    } else if (targetDate == tomorrow) {
      dateStr = '明天';
    } else if (targetDate == yesterday) {
      dateStr = '昨天';
    } else if (dateTime.year == now.year) {
      dateStr = '${dateTime.month}月${dateTime.day}日';
    } else {
      dateStr = '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
  }
}
