// lib/pages/index/widgets/grade_brief.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/grade_provider.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../../lifeService/pages/grade_query_screen.dart';

/// 成绩简要组件
class GradeBrief extends ConsumerWidget {
  final bool blur;
  final bool darkMode;

  const GradeBrief({super.key, required this.blur, required this.darkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeState = ref.watch(gradeProvider);
    final statistics = ref.watch(gradeStatisticsProvider);
    final sortedGrades = ref.watch(sortedGradesProvider);

    // 获取主题色
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    final textColor = darkMode ? Colors.white70 : Colors.black87;
    final subtitleColor = darkMode ? Colors.white54 : Colors.black54;

    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToGradeQuery(context),
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
                          Icons.school_outlined,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '成绩',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // 右上角箭头和状态
                  Row(
                    children: [
                      // 显示加载状态或NEW标识
                      if (gradeState.isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              themeColor,
                            ),
                          ),
                        )
                      else if (_hasNewGrades(gradeState))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(204),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // 箭头图标
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToGradeQuery(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 根据状态显示不同内容
              if (statistics != null && !gradeState.isLoading) ...[
                _buildGradeContent(
                  statistics,
                  sortedGrades,
                  textColor,
                  subtitleColor,
                  gradeState,
                ),
              ] else if (gradeState.error != null) ...[
                _buildErrorState(textColor, subtitleColor, ref),
              ] else ...[
                _buildEmptyState(textColor, subtitleColor, ref),
              ],
            ],
          ),
        ),
      ),
    );

    return _applyContainerStyle(child);
  }

  /// 构建成绩内容
  Widget _buildGradeContent(
    statistics,
    sortedGrades,
    Color textColor,
    Color subtitleColor,
    gradeState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 成绩统计信息 - 5项指标
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: darkMode
                  ? [
                      Colors.green.shade800.withAlpha(26),
                      Colors.blue.shade800.withAlpha(26),
                    ]
                  : [
                      Colors.green.shade500.withAlpha(26),
                      Colors.blue.shade500.withAlpha(26),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withAlpha(51), width: 1),
          ),
          child: Column(
            children: [
              // 第一行：必修加权均分和全科加权均分
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '必修加权均分',
                      statistics.compulsoryAverage.toStringAsFixed(2),
                      Colors.red.shade700,
                      subtitleColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.green.withAlpha(76),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '全科加权均分',
                      statistics.totalAverage.toStringAsFixed(2),
                      Colors.orange.shade700,
                      subtitleColor,
                    ),
                  ),
                ],
              ),

              // 分割线
              Container(
                height: 1,
                color: Colors.green.withAlpha(76),
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),

              // 第二行：必修GPA、全科GPA和总学分
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '必修 GPA',
                      statistics.compulsoryGpa.toStringAsFixed(2),
                      Colors.purple.shade700,
                      subtitleColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.green.withAlpha(76),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '全科 GPA',
                      statistics.totalGpa.toStringAsFixed(2),
                      Colors.green.shade700,
                      subtitleColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.green.withAlpha(76),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '总学分',
                      statistics.totalCredits.toString(),
                      Colors.blue.shade700,
                      subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 最新成绩
        if (sortedGrades.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最新成绩',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${sortedGrades.length}门课程',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 成绩列表（最多显示3个）
          ...sortedGrades
              .take(3)
              .map((grade) => _buildGradeItem(grade, textColor, subtitleColor)),

          const SizedBox(height: 8),
        ],

        // 更新时间
        if (gradeState.lastUpdateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '更新时间: ${_formatUpdateTime(gradeState.lastUpdateTime!)}',
              style: TextStyle(color: subtitleColor, fontSize: 11),
            ),
          ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(Color textColor, Color subtitleColor, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withAlpha(178),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text('点击重试', style: TextStyle(color: subtitleColor, fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ref.read(gradeProvider.notifier).refreshGrades(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withAlpha(204),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(Color textColor, Color subtitleColor, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.school_outlined, color: subtitleColor, size: 32),
            const SizedBox(height: 8),
            Text(
              '暂无成绩信息',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '点击刷新获取最新成绩',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ref.read(gradeProvider.notifier).refreshGrades(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('刷新成绩'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withAlpha(204),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项目
  Widget _buildStatItem(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建单个成绩项目
  Widget _buildGradeItem(grade, Color textColor, Color subtitleColor) {
    final scoreColor = _getScoreColor(grade.zcj);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scoreColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scoreColor.withAlpha(51), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.kcmc,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '学分: ${grade.xf}',
                      style: TextStyle(color: subtitleColor, fontSize: 11),
                    ),
                    if (grade.kcxzmc != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                          color: subtitleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        grade.kcxzmc!,
                        style: TextStyle(
                          color: grade.kcxzmc!.contains('必')
                              ? Colors.red.withAlpha(178)
                              : subtitleColor,
                          fontSize: 11,
                          fontWeight: grade.kcxzmc!.contains('必')
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade.zcj.toString(),
              style: TextStyle(
                color: scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据分数获取颜色
  Color _getScoreColor(dynamic score) {
    if (score is String) {
      switch (score) {
        case '优':
        case 'A':
          return Colors.green;
        case '良':
        case 'B':
          return Colors.blue;
        case '中':
        case 'C':
          return Colors.orange;
        case '及格':
        case 'D':
          return Colors.amber;
        case '不及格':
        case 'E':
          return Colors.red;
      }
    }

    final numScore = double.tryParse(score.toString());
    if (numScore == null) return Colors.grey;

    if (numScore >= 90) return Colors.green;
    if (numScore >= 80) return Colors.blue;
    if (numScore >= 70) return Colors.orange;
    if (numScore >= 60) return Colors.amber;
    return Colors.red;
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

  /// 判断是否有新成绩
  bool _hasNewGrades(gradeState) {
    if (gradeState.lastUpdateTime == null) return false;
    final now = DateTime.now();
    final diff = now.difference(gradeState.lastUpdateTime!);
    return diff.inHours < 24 && gradeState.calculatedGrades.isNotEmpty;
  }

  /// 格式化更新时间
  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}-${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 导航到成绩查询页面
  void _navigateToGradeQuery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GradeQueryScreen()),
    );
  }
}
