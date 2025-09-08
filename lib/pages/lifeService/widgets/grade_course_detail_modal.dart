// lib/pages/lifeService/widgets/grade_course_detail_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/models/grade_models.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/constants/route_constants.dart';

/// 课程详情弹窗
class GradeCourseDetailModal extends ConsumerWidget {
  final CalculatedGrade grade;

  const GradeCourseDetailModal({super.key, required this.grade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final examHistory = ref
        .read(gradeProvider.notifier)
        .getCourseExamHistory(grade.kchId);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '考试详情',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              grade.kcmc,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 分割线
            Container(
              height: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 考试记录
                    if (examHistory.isNotEmpty) ...[
                      _buildExamHistorySection(examHistory, isDarkMode),
                      const SizedBox(height: 20),
                    ],

                    // 课程信息
                    _buildCourseInfoSection(grade, isDarkMode),

                    const SizedBox(height: 20),

                    // 统计数据查看按钮
                    _buildStatisticsButton(grade, isDarkMode, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建考试记录部分
  Widget _buildExamHistorySection(
    List<GradeDetail> examHistory,
    bool isDarkMode,
  ) {
    // 按学期分组考试记录
    final Map<String, List<GradeDetail>> groupedExams = {};
    for (final exam in examHistory) {
      final key = '${exam.xnmmc}-${exam.xqmmc}';
      groupedExams.putIfAbsent(key, () => []).add(exam);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '考试记录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        ...groupedExams.entries.map((entry) {
          final semesterName = entry.key;
          final exams = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 学期标题
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  semesterName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  ),
                ),
              ),

              // 该学期的考试记录
              ...exams.map((exam) => _buildExamItem(exam, isDarkMode)),
            ],
          );
        }),
      ],
    );
  }

  /// 构建单个考试项
  Widget _buildExamItem(GradeDetail exam, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exam.xmblmc,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getScoreColor(exam.xmcj, isDarkMode).withAlpha(51),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              exam.xmcj,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getScoreColor(exam.xmcj, isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建课程信息部分
  Widget _buildCourseInfoSection(CalculatedGrade grade, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '课程信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        _buildInfoRow('教师', grade.teacher ?? '未知', isDarkMode),
        _buildInfoRow(
          '课程性质',
          grade.kcxzmc ?? '未知',
          isDarkMode,
          valueColor: (grade.kcxzmc?.contains('必') ?? false)
              ? Colors.red.withAlpha(178)
              : null,
        ),
        _buildInfoRow('课程类别', grade.kclbmc ?? '未知', isDarkMode),
        _buildInfoRow('学分', grade.xf, isDarkMode),
        _buildInfoRow('成绩', grade.zcj.toString(), isDarkMode),
        _buildInfoRow('绩点', grade.jd, isDarkMode),
        if (grade.ksxz != null) _buildInfoRow('考试性质', grade.ksxz!, isDarkMode),
      ],
    );
  }

  /// 构建统计数据查看按钮
  Widget _buildStatisticsButton(
    CalculatedGrade grade,
    bool isDarkMode,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // 关闭当前模态框
        Navigator.of(context).pop();
        // 导航到统计页面，传递课程代码参数
        context.push(
          '${RouteConstants.statistics}?kch=${grade.kch}&courseName=${Uri.encodeComponent(grade.kcmc)}',
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.blue.shade800.withAlpha(128)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.blue.shade600 : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '点此处查看课程统计数据',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    String label,
    String value,
    bool isDarkMode, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取成绩颜色
  Color _getScoreColor(String score, bool isDarkMode) {
    if (score.isEmpty) {
      return isDarkMode ? Colors.white70 : Colors.black54;
    }

    // 处理等级成绩
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

    // 处理数字成绩
    final numScore = double.tryParse(score);
    if (numScore == null) {
      return isDarkMode ? Colors.white70 : Colors.black54;
    }

    if (numScore >= 90) {
      return Colors.green;
    } else if (numScore >= 80) {
      return Colors.blue;
    } else if (numScore >= 70) {
      return Colors.orange;
    } else if (numScore >= 60) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
}
