// lib/pages/index/widgets/expense_brief.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import 'package:go_router/go_router.dart';
import '../../lifeService/providers/expense_provider.dart';
import '../../lifeService/widgets/expense_bind_dialog.dart';

/// 水电费简要组件
class ExpenseBrief extends ConsumerWidget {
  final bool blur;
  final bool darkMode;

  const ExpenseBrief({super.key, required this.blur, required this.darkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseBrief = ref.watch(expenseBriefProvider);
    final expenseState = ref.watch(expenseProvider);

    // 获取主题色
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;

    final textColor = darkMode ? Colors.white70 : Colors.black87;
    final subtitleColor = darkMode ? Colors.white54 : Colors.black54;

    // 添加状态安全检查
    debugPrint(
      'ExpenseBrief build: isBound=${expenseState.isBound}, isLoading=${expenseState.isLoading}, hasData=${expenseBrief != null}',
    );

    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToExpensePage(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                          Icons.electrical_services_outlined,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '水电费',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // 右上角箭头图标（现在只是装饰性的，不再单独可点击）
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: themeColor,
                      size: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 内容区域
              if (expenseState.isBound && expenseBrief != null) ...[
                // 余额信息
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMainBalanceCard(
                          '水电余额',
                          '¥${expenseBrief.currentBalance.toStringAsFixed(2)}',
                          textColor,
                          subtitleColor,
                          themeColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildExpenseItem(
                              '昨日电费',
                              expenseBrief.electricityFee,
                              Icons.bolt,
                              Colors.amber,
                              textColor,
                              subtitleColor,
                            ),
                            const SizedBox(height: 8),
                            _buildExpenseItem(
                              '昨日水费',
                              expenseBrief.waterFee,
                              Icons.water_drop,
                              Colors.blue,
                              textColor,
                              subtitleColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 消费对比
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeColor.withAlpha(26),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '消费趋势',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: expenseBrief.isIncrease
                              ? Colors.red.withAlpha(26)
                              : Colors.green.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          expenseBrief.compareText,
                          style: TextStyle(
                            color: expenseBrief.isIncrease
                                ? Colors.red
                                : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (expenseBrief.updateTime != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '更新于 ${_formatUpdateTime(expenseBrief.updateTime!)}',
                    style: TextStyle(color: subtitleColor, fontSize: 11),
                  ),
                ],
              ] else if (expenseState.isLoading) ...[
                // 加载状态
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: themeColor,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '正在获取水电费信息...',
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (expenseState.error != null) ...[
                // 错误状态
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '获取数据失败',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expenseState.error!,
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(expenseProvider.notifier)
                              .refreshExpenseData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // 未绑定宿舍状态
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.home_outlined,
                            color: themeColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未绑定宿舍',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '绑定宿舍信息以查看水电费',
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showBindDialog(context, ref),
                          icon: const Icon(Icons.add_home, size: 18),
                          label: const Text('绑定宿舍'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return _applyContainerStyle(child);
  }

  /// 构建主要余额卡片
  Widget _buildMainBalanceCard(
    String title,
    String value,
    Color textColor,
    Color subtitleColor,
    Color themeColor,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withAlpha(26), themeColor.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withAlpha(51), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: themeColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个费用项目
  Widget _buildExpenseItem(
    String title,
    double amount,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withAlpha(51), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                Text(
                  '¥${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 应用容器样式和模糊效果
  Widget _applyContainerStyle(Widget child) {
    Widget styledChild = Container(
      decoration: BoxDecoration(
        color: darkMode
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

    if (blur) {
      styledChild = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: darkMode
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

  /// 导航到水电费查询页面
  void _navigateToExpensePage(BuildContext context) {
    context.push('/lifeService/expense');
  }

  /// 显示绑定宿舍对话框
  void _showBindDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // 防止意外关闭
      builder: (context) => ExpenseBindDialog(
        onBind: (buildingId, roomCode) async {
          try {
            debugPrint('ExpenseBrief: 开始绑定宿舍操作');

            // 先关闭对话框，避免状态更新时对话框还在显示
            if (context.mounted) {
              Navigator.of(context).pop();
              debugPrint('ExpenseBrief: 对话框已关闭');
            }

            // 给UI一些时间稳定
            await Future.delayed(const Duration(milliseconds: 200));

            // 执行绑定操作
            await ref
                .read(expenseProvider.notifier)
                .bindDormitory(buildingId, roomCode);
            debugPrint('ExpenseBrief: 绑定宿舍操作完成');

            // 再次延迟，确保状态完全更新
            await Future.delayed(const Duration(milliseconds: 300));

            // 显示成功提示
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('宿舍绑定成功！'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('ExpenseBrief: 绑定失败: $e');

            if (context.mounted) {
              // 显示错误提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('绑定失败: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        onCancel: () {
          debugPrint('ExpenseBrief: 用户取消绑定');
        },
      ),
    );
  }

  /// 格式化更新时间
  String _formatUpdateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }
}
