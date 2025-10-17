// lib/pages/index/widgets/todo_brief.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';
import 'todo_edit_modal.dart';
import '../../../core/config/providers/new_core_providers.dart';
import '../../../core/config/models/app_config.dart';

/// 待办事项简要组件
class TodoBrief extends ConsumerStatefulWidget {
  final bool blur;
  final bool darkMode;

  const TodoBrief({super.key, required this.blur, required this.darkMode});

  @override
  ConsumerState<TodoBrief> createState() => _TodoBriefState();
}

class _TodoBriefState extends ConsumerState<TodoBrief>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 处理刷新操作，包含动画和提示
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return; // 防止重复点击

    setState(() {
      _isRefreshing = true;
    });

    // 开始旋转动画
    _refreshController.repeat();

    try {
      // 执行刷新操作
      await ref.read(todoProvider.notifier).refresh();

      // 刷新成功提示和触觉反馈
      if (mounted) {
        HapticFeedback.lightImpact(); // 轻微触觉反馈
        _showRefreshNotification(true, '刷新成功');
      }
    } catch (e) {
      // 刷新失败提示和触觉反馈
      if (mounted) {
        HapticFeedback.heavyImpact(); // 较重触觉反馈表示错误
        _showRefreshNotification(false, '刷新失败: ${e.toString()}');
      }
    } finally {
      // 停止动画
      _refreshController.stop();
      _refreshController.reset();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// 显示刷新结果通知
  void _showRefreshNotification(bool isSuccess, String message) {
    if (!mounted) return;

    final backgroundColor =
        isSuccess ? Colors.green.shade600 : Colors.red.shade600;
    final duration =
        Duration(milliseconds: isSuccess ? 2000 : 3000);

    ToastService.show(
      message,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      duration: duration,
    );

    if (!isSuccess) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('刷新失败'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleRefresh();
              },
              child: const Text('重试'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    }
  }

  /// 处理待办事项完成状态切换，包含位置过渡动画
  Future<void> _handleToggleTodo(int todoId, bool currentStatus) async {
    // 直接调用toggle操作，让TweenAnimationBuilder处理位置过渡
    // 由于每个待办事项都有唯一的key: ValueKey('${todo.id}_${category.name}')
    // 当category改变时，会自动触发新的动画
    ref.read(todoProvider.notifier).toggleTodo(todoId);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? Colors.white70 : Colors.black87;
    final subtitleColor = widget.darkMode ? Colors.white54 : Colors.black54;
    // 获取主题色，如果没有主题则使用默认蓝色
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;

    Widget child = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.checklist_rtl,
                      color: themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '待办事项',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // 刷新按钮 - 添加旋转动画
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleRefresh,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isRefreshing
                              ? Colors.blue.withAlpha(26)
                              : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _refreshController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _refreshController.value * 2 * 3.14159,
                                child: Icon(
                                  Icons.refresh,
                                  color: _isRefreshing
                                      ? Colors.blue
                                      : Colors.grey.shade600,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 添加按钮
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showTodoEditModal(context, null, ref),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.add, color: themeColor, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 待办事项内容
          _buildTodoContent(context, ref, textColor, subtitleColor, themeColor),
        ],
      ),
    );

    // 应用容器样式和模糊效果
    return _applyContainerStyle(child);
  }

  /// 构建待办事项内容区域
  Widget _buildTodoContent(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color subtitleColor,
    Color themeColor,
  ) {
    final allTodos = ref.watch(todoProvider);
    final appConfigAsync = ref.watch(appConfigNotifierProvider);

    return appConfigAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: themeColor)),
      error: (_, __) => _buildEmptyState(subtitleColor),
      data: (appConfig) {
        // 根据配置过滤待办事项
        final filteredTodos = appConfig.showFinishedTodo
            ? allTodos
            : allTodos.where((todo) => !todo.finished).toList();

        debugPrint('TodoBrief: 原始待办事项数量: ${allTodos.length}');
        debugPrint('TodoBrief: 过滤后待办事项数量: ${filteredTodos.length}');
        debugPrint(
          'TodoBrief: showFinishedTodo配置: ${appConfig.showFinishedTodo}',
        );

        if (filteredTodos.isEmpty) {
          debugPrint('TodoBrief: 显示空状态');
          return _buildEmptyState(subtitleColor);
        }

        return _buildFilteredTodoContent(
          context,
          ref,
          filteredTodos,
          appConfig,
          textColor,
          subtitleColor,
          themeColor,
        );
      },
    );
  }

  Widget _buildFilteredTodoContent(
    BuildContext context,
    WidgetRef ref,
    List<TodoItem> filteredTodos,
    AppConfig appConfig,
    Color textColor,
    Color subtitleColor,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.overdue,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.today,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.tomorrow,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.thisWeek,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.future,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        _buildTodoSectionWithData(
          context,
          ref,
          TodoCategory.noDueTime,
          filteredTodos,
          textColor,
          subtitleColor,
          themeColor,
        ),
        // 只有当配置允许显示已完成待办时才显示completed分类
        if (appConfig.showFinishedTodo)
          _buildTodoSectionWithData(
            context,
            ref,
            TodoCategory.completed,
            filteredTodos,
            textColor,
            subtitleColor,
            themeColor,
          ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.task_alt, color: subtitleColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无待办事项',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方 + 按钮添加新任务',
              style: TextStyle(
                color: subtitleColor.withAlpha(178),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建待办事项分组（使用过滤后的数据）
  Widget _buildTodoSectionWithData(
    BuildContext context,
    WidgetRef ref,
    TodoCategory category,
    List<TodoItem> allFilteredTodos,
    Color textColor,
    Color subtitleColor,
    Color themeColor,
  ) {
    // 从过滤后的数据中按类别筛选（使用与provider相同的逻辑）
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
    final oneWeekLater = now.add(const Duration(days: 7));

    List<TodoItem> todos = allFilteredTodos.where((todo) {
      switch (category) {
        case TodoCategory.overdue:
          return !todo.finished && todo.due != null && todo.due!.isBefore(now);
        case TodoCategory.today:
          if (todo.finished || todo.due == null) return false;
          return todo.due!.isAfter(now) && todo.due!.isBefore(tomorrow);
        case TodoCategory.tomorrow:
          if (todo.finished || todo.due == null) return false;
          return todo.due!.isAfter(tomorrow) &&
              todo.due!.isBefore(dayAfterTomorrow);
        case TodoCategory.thisWeek:
          if (todo.finished || todo.due == null) return false;
          return todo.due!.isAfter(now) &&
              todo.due!.isBefore(oneWeekLater) &&
              !todo.due!.isBefore(dayAfterTomorrow);
        case TodoCategory.future:
          if (todo.finished || todo.due == null) return false;
          return todo.due!.isAfter(oneWeekLater);
        case TodoCategory.noDueTime:
          return !todo.finished && todo.due == null;
        case TodoCategory.completed:
          return todo.finished;
      }
    }).toList();

    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }

    // 显示所有待办事项
    final displayTodos = todos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayTodos.isNotEmpty) ...[
          const SizedBox(height: 12),
          // 分类标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category.displayName,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 待办事项列表
          ...displayTodos.map(
            (todo) => _buildTodoItem(
              context,
              ref,
              todo,
              category,
              textColor,
              subtitleColor,
              themeColor,
            ),
          ),
        ],
      ],
    );
  }


  /// 构建单个待办事项
  Widget _buildTodoItem(
    BuildContext context,
    WidgetRef ref,
    TodoItem todo,
    TodoCategory category,
    Color textColor,
    Color subtitleColor,
    Color themeColor,
  ) {
    final isCompleted = category == TodoCategory.completed;
    final isOverdue = category == TodoCategory.overdue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTodoEditModal(context, todo, ref),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.grey.withAlpha(13)
                : isOverdue
                ? Colors.red.withAlpha(13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? Colors.grey.withAlpha(51)
                  : isOverdue
                  ? Colors.red.withAlpha(76)
                  : Colors.grey.withAlpha(26),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 复选框图标 - 添加完成动画
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleToggleTodo(todo.id, todo.finished),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withAlpha(26)
                          : _getCategoryColor(category).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: Colors.green.withAlpha(76),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: isCompleted
                            ? Icon(
                                Icons.check_circle,
                                key: const ValueKey('completed'),
                                color: Colors.green,
                                size: 24,
                              )
                            : Icon(
                                category.icon,
                                key: const ValueKey('incomplete'),
                                size: 20,
                                color: _getCategoryColor(category),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 待办事项信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        // 重要性标识
                        if (todo.important && !isCompleted)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '重要',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // 标题 - 添加完成动画
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? Colors.grey.withAlpha(153)
                                  : textColor,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            child: Text(
                              todo.title,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 截止时间
                    if (todo.due != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.withAlpha(26)
                              : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatRelativeTime(todo.due!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isCompleted
                                ? Colors.grey.withAlpha(153)
                                : isOverdue
                                ? Colors.red
                                : (todo.important
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade600),
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
    );
  }

  /// 获取分类颜色
  Color _getCategoryColor(TodoCategory category) {
    switch (category) {
      case TodoCategory.overdue:
        return Colors.red;
      case TodoCategory.today:
        return Colors.blue;
      case TodoCategory.tomorrow:
        return Colors.orange;
      case TodoCategory.thisWeek:
        return Colors.green;
      case TodoCategory.future:
        return Colors.purple;
      case TodoCategory.noDueTime:
        return Colors.grey;
      case TodoCategory.completed:
        return Colors.green;
    }
  }

  /// 应用容器样式和模糊效果
  Widget _applyContainerStyle(Widget child) {
    Widget styledChild = Container(
      decoration: BoxDecoration(
        color: widget.darkMode
            ? Colors.grey.shade900.withAlpha(230)
            : Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (widget.blur) {
      styledChild = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: widget.darkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: widget.darkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
            ),
            child: child,
          ),
        ),
      );
    }

    return styledChild;
  }

  /// 显示待办事项编辑模态框
  void _showTodoEditModal(BuildContext context, TodoItem? todo, WidgetRef ref) {
    final currentTheme = ref.read(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TodoEditModal(
        initialTodo: todo,
        darkMode: widget.darkMode,
        themeColor: themeColor,
      ),
    );
  }

  /// 格式化相对时间
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // 已经过去的时间
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes}分钟前';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours}小时前';
      } else if (absDifference.inDays < 7) {
        return '${absDifference.inDays}天前';
      } else {
        return '很久之前';
      }
    } else {
      // 未来的时间
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟后';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时后';
      } else if (difference.inDays == 0) {
        return '今天';
      } else if (difference.inDays == 1) {
        return '明天';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天后';
      } else {
        return '很久以后';
      }
    }
  }
}
