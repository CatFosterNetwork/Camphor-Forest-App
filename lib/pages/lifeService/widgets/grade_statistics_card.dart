// lib/pages/lifeService/widgets/grade_statistics_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/providers/grade_provider.dart';

/// 成绩统计卡片组件
class GradeStatisticsCard extends ConsumerWidget {
  const GradeStatisticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final statistics = ref.watch(gradeStatisticsProvider);

    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withAlpha(128) : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '成绩统计',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 统计数据网格
          _buildStatisticsGrid(statistics, isDarkMode),
        ],
      ),
    );
  }

  /// 构建统计数据网格
  Widget _buildStatisticsGrid(statistics, bool isDarkMode) {
    return Column(
      children: [
        // 第一行：平均分
        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                '必修加权均分',
                statistics.compulsoryAverage.toStringAsFixed(2),
                Icons.school_outlined,
                Colors.green,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticItem(
                '全科加权均分',
                statistics.totalAverage.toStringAsFixed(2),
                Icons.grade_outlined,
                Colors.blue,
                isDarkMode,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 第二行：GPA
        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                '必修 GPA',
                statistics.compulsoryGpa.toStringAsFixed(2),
                Icons.emoji_events_outlined,
                Colors.orange,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticItem(
                '全科 GPA',
                statistics.totalGpa.toStringAsFixed(2),
                Icons.workspace_premium_outlined,
                Colors.purple,
                isDarkMode,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 第三行：学分统计
        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                '必修学分',
                statistics.compulsoryCredits.toString(),
                Icons.credit_card_outlined,
                Colors.teal,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticItem(
                '总学分',
                statistics.totalCredits.toString(),
                Icons.account_balance_outlined,
                Colors.indigo,
                isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个统计项
  Widget _buildStatisticItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(isDarkMode ? 51 : 25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
