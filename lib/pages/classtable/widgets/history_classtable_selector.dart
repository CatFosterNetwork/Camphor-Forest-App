import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../providers/classtable_settings_provider.dart';
import '../models/custom_course_model.dart';

/// 历史课表选择器
class HistoryClassTableSelector extends ConsumerWidget {
  const HistoryClassTableSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final settings = ref.watch(classTableSettingsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white38 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '历史课表',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Divider(
            color: isDarkMode ? Colors.white12 : Colors.black12,
            thickness: 1,
            height: 1,
          ),

          // 历史课表列表
          if (settings.historyClassTables.isEmpty)
            _buildEmptyState(isDarkMode, ref, context)
          else
            _buildHistoryList(settings, isDarkMode, theme, ref, context),

          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(
    bool isDarkMode,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无历史课表',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '历史课表会从成绩数据中自动提取',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(classTableSettingsProvider.notifier)
                  .refreshHistoryFromGrades();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('正在从成绩数据刷新历史课表...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('从成绩数据刷新'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建历史课表列表
  Widget _buildHistoryList(
    ClassTableSettingsState settings,
    bool isDarkMode,
    ThemeData theme,
    WidgetRef ref,
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: settings.historyClassTables.length,
        itemBuilder: (context, index) {
          final historyTable = settings.historyClassTables[index];
          final isCurrentSemester =
              historyTable.xnm == settings.currentXnm &&
              historyTable.xqm == settings.currentXqm;

          return _buildHistoryItem(
            historyTable,
            isCurrentSemester,
            isDarkMode,
            theme,
            ref,
            context,
          );
        },
      ),
    );
  }

  /// 构建历史课表项
  Widget _buildHistoryItem(
    HistoryClassTable historyTable,
    bool isCurrentSemester,
    bool isDarkMode,
    ThemeData theme,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentSemester
            ? theme.primaryColor.withOpacity(0.1)
            : (isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentSemester
            ? Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCurrentSemester
              ? null
              : () => _switchToSemester(
                  historyTable.xnm,
                  historyTable.xqm,
                  ref,
                  context,
                ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 学期图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentSemester
                        ? theme.primaryColor.withOpacity(0.2)
                        : (isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: isCurrentSemester
                        ? theme.primaryColor
                        : (isDarkMode ? Colors.white54 : Colors.black54),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // 学期信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyTable.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCurrentSemester
                              ? theme.primaryColor
                              : (isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                // 状态指示器
                if (isCurrentSemester)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '当前',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? Colors.white38 : Colors.black26,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 切换到指定学期
  Future<void> _switchToSemester(
    String xnm,
    String xqm,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      await ref
          .read(classTableSettingsProvider.notifier)
          .switchSemester(xnm, xqm);

      if (context.mounted) {
        Navigator.of(context).pop();

        // 显示成功提示
        final displayName = _formatSemesterDisplayName(xnm, xqm);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到 $displayName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 格式化学期显示名称
  String _formatSemesterDisplayName(String xnm, String xqm) {
    final year = int.tryParse(xnm) ?? DateTime.now().year;
    if (xqm == '12') {
      return '${year + 1}年春季学期';
    } else if (xqm == '3') {
      return '${year}年秋季学期';
    } else {
      return '${year}年夏季学期';
    }
  }
}
