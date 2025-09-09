// lib/pages/lifeService/widgets/grade_normal_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/models/grade_models.dart';
import '../../../core/providers/grade_provider.dart';
import 'grade_statistics_card.dart';
import 'grade_course_detail_modal.dart';

/// 普通成绩Tab页
class GradeNormalTab extends ConsumerWidget {
  const GradeNormalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final gradeState = ref.watch(gradeProvider);
    final sortedGrades = ref.watch(sortedGradesProvider);
    final currentSemester = ref.watch(currentSemesterProvider);
    final availableSemesters = ref.watch(sortedAvailableSemestersProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    return RefreshIndicator(
      onRefresh: () => ref.read(gradeProvider.notifier).refreshGrades(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学期选择器
            _buildSemesterSelector(
              context,
              currentSemester,
              availableSemesters,
              isDarkMode,
              themeColor,
              ref,
            ),

            const SizedBox(height: 16),

            // 成绩列表卡片
            _buildGradeListCard(
              context,
              sortedGrades,
              gradeState,
              isDarkMode,
              themeColor,
              ref,
            ),

            const SizedBox(height: 16),

            // 统计信息卡片
            const GradeStatisticsCard(),

            const SizedBox(height: 80), // 底部间距
          ],
        ),
      ),
    );
  }

  /// 构建学期选择器
  Widget _buildSemesterSelector(
    BuildContext context,
    SemesterInfo currentSemester,
    List<SemesterInfo> availableSemesters,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(25), // 改为圆弧样式
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSemesterPicker(
          context,
          availableSemesters,
          currentSemester,
          isDarkMode,
          themeColor,
          ref,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentSemester.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建成绩列表卡片
  Widget _buildGradeListCard(
    BuildContext context,
    List<CalculatedGrade> grades,
    GradeState gradeState,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
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
          // 标题栏和排序按钮
          _buildGradeListHeader(gradeState.sortBy, isDarkMode, themeColor, ref),

          // 成绩列表
          if (gradeState.isLoading)
            _buildLoadingState(isDarkMode)
          else if (gradeState.error != null)
            _buildErrorState(gradeState.error!, isDarkMode, themeColor, ref)
          else if (grades.isEmpty)
            _buildEmptyState(isDarkMode)
          else
            _buildGradeList(context, grades, isDarkMode, ref),

          const SizedBox(height: 20),

          // 刷新按钮
          if (!gradeState.isLoading)
            _buildRefreshButton(
              gradeState.isLoading,
              isDarkMode,
              themeColor,
              ref,
            ),

          const SizedBox(height: 20), // 添加底部间距
        ],
      ),
    );
  }

  /// 构建成绩列表标题栏
  Widget _buildGradeListHeader(
    GradeSortBy currentSortBy,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildSortButton(
            '课程名称',
            GradeSortBy.course,
            currentSortBy,
            isDarkMode,
            themeColor,
            ref,
            flex: 2,
          ),
          _buildSortButton(
            '学分',
            GradeSortBy.credit,
            currentSortBy,
            isDarkMode,
            themeColor,
            ref,
            flex: 1,
          ),
          _buildSortButton(
            '成绩',
            GradeSortBy.score,
            currentSortBy,
            isDarkMode,
            themeColor,
            ref,
            flex: 1,
          ),
          _buildSortButton(
            '绩点',
            GradeSortBy.gpa,
            currentSortBy,
            isDarkMode,
            themeColor,
            ref,
            flex: 1,
          ),
        ],
      ),
    );
  }

  /// 构建排序按钮
  Widget _buildSortButton(
    String title,
    GradeSortBy sortBy,
    GradeSortBy currentSortBy,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref, {
    int flex = 1,
  }) {
    final isActive = currentSortBy == sortBy;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => ref.read(gradeProvider.notifier).changeSortBy(sortBy),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.blue.shade300 : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '加载成绩中...',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(
    String error,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDarkMode ? Colors.red.shade300 : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(gradeProvider.notifier).refreshGrades(),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无成绩数据',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请刷新或切换学期查看',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建成绩列表
  Widget _buildGradeList(
    BuildContext context,
    List<CalculatedGrade> grades,
    bool isDarkMode,
    WidgetRef ref,
  ) {
    return Column(
      children: grades
          .map((grade) => _buildGradeItem(context, grade, isDarkMode, ref))
          .toList(),
    );
  }

  /// 构建单个成绩项
  Widget _buildGradeItem(
    BuildContext context,
    CalculatedGrade grade,
    bool isDarkMode,
    WidgetRef ref,
  ) {
    final scoreColor = _getScoreColor(grade.zcj, isDarkMode);

    return InkWell(
      onTap: () => _showCourseDetail(context, grade, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 课程名称
            Expanded(
              flex: 2,
              child: Text(
                grade.kcmc,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 学分
            Expanded(
              flex: 1,
              child: Text(
                grade.xf,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 成绩
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  grade.zcj.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 绩点
            Expanded(
              flex: 1,
              child: Text(
                grade.jd,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton(
    bool isLoading,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => ref.read(gradeProvider.notifier).refreshGrades(),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // 改为圆弧样式
          ),
        ),
        child: Text(
          isLoading ? '刷新中...' : '刷新成绩',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 显示学期选择器
  void _showSemesterPicker(
    BuildContext context,
    List<SemesterInfo> availableSemesters,
    SemesterInfo currentSemester,
    bool isDarkMode,
    Color themeColor,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '选择学期',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),

            // 学期列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSemesters.length,
                itemBuilder: (context, index) {
                  final semester = availableSemesters[index];
                  final isSelected =
                      semester.xnm == currentSemester.xnm &&
                      semester.xqm == currentSemester.xqm;

                  return ListTile(
                    title: Text(
                      semester.displayName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: themeColor)
                        : null,
                    onTap: () {
                      ref.read(gradeProvider.notifier).changeSemester(semester);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 显示课程详情
  void _showCourseDetail(
    BuildContext context,
    CalculatedGrade grade,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => GradeCourseDetailModal(grade: grade),
    );
  }

  /// 获取成绩颜色
  Color _getScoreColor(dynamic score, bool isDarkMode) {
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
