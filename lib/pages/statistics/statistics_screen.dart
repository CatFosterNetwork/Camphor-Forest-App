// lib/pages/statistics/statistics_screen.dart

import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/providers/grade_provider.dart' as grade_provider;
import '../../widgets/app_background.dart';
import 'models/statistics_model.dart';
import 'providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  final String? kch; // 课程代码
  final String? courseName; // 课程名称

  const StatisticsScreen({super.key, this.kch, this.courseName});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedCourseId;
  String? _selectedCourseName;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.kch;
    _selectedCourseName = widget.courseName;

    // 如果传入了课程ID，需要找到对应的学期并设置
    if (widget.kch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _findAndSetSemesterForCourse(widget.kch!);
        // 初始化完成
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      });
    } else {
      _isInitializing = false;
    }
  }

  Future<void> _findAndSetSemesterForCourse(String courseId) async {
    try {
      AppLogger.debug('🔍 查找课程 $courseId 对应的学期...');
      final gradeState = ref.read(grade_provider.gradeProvider);

      // 从成绩数据中找到对应课程的学期信息
      final gradeDetails = gradeState.gradeDetails;
      for (final detail in gradeDetails) {
        if (detail.kch == courseId) {
          final targetSemester = SemesterInfo(
            xnm: detail.xnm,
            xqm: detail.xqm,
            displayName: _formatSemesterDisplay(detail.xnm, detail.xqm),
          );

          AppLogger.info(
            '✅ 找到课程 ${detail.kcmc} 的学期: ${targetSemester.displayName}',
          );

          // 检查这个学期是否在可选列表中
          final availableSemesters = ref.read(availableSemestersProvider);
          final semesterExists = availableSemesters.any(
            (semester) =>
                semester.xnm == targetSemester.xnm &&
                semester.xqm == targetSemester.xqm,
          );

          if (semesterExists) {
            ref.read(selectedSemesterProvider.notifier).state = targetSemester;
            AppLogger.info('✅ 已切换到学期: ${targetSemester.displayName}');

            // 等待一帧，确保学期切换完成
            await Future.delayed(const Duration(milliseconds: 100));
          } else {
            AppLogger.warning('⚠️ 学期 ${targetSemester.displayName} 不在可选列表中');
          }
          break;
        }
      }
    } catch (e) {
      AppLogger.error('❌ 查找课程学期失败: $e');
    }
  }

  String _formatSemesterDisplay(String xnm, String xqm) {
    final year = int.tryParse(xnm) ?? DateTime.now().year;
    if (xqm == '3') {
      return '$year年秋季学期';
    } else if (xqm == '12') {
      return '${year + 1}年春季学期';
    }
    return '$xnm-$xqm学期';
  }

  // 获取个人成绩
  double? _getPersonalScore(String courseId) {
    try {
      final gradeState = ref.read(grade_provider.gradeProvider);
      AppLogger.debug('🔍 查找个人成绩: courseId=$courseId');
      AppLogger.debug('📊 总成绩数量: ${gradeState.gradeDetails.length}');

      // 从成绩数据中找到对应课程的个人成绩
      for (final detail in gradeState.gradeDetails) {
        AppLogger.debug(
          '🔍 检查成绩: ${detail.kcmc} (kch: ${detail.kch}, 成绩: ${detail.xmcj})',
        );
        if (detail.kch == courseId) {
          // 尝试解析成绩为数字
          final score = double.tryParse(detail.xmcj.toString());
          AppLogger.info('✅ 找到个人成绩: $score');
          return score;
        }
      }
      AppLogger.error('❌ 未找到个人成绩');
      return null;
    } catch (e) {
      AppLogger.error('❌ 获取个人成绩失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final selectedSemester = ref.watch(selectedSemesterProvider);

    // 获取当前学期的课程列表
    final semesterCoursesAsync = ref.watch(
      semesterCoursesProvider(selectedSemester),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(blur: false),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isDarkMode),
                _buildSemesterSelector(isDarkMode),
                _buildCourseSelector(semesterCoursesAsync, isDarkMode),
                Expanded(
                  child: _selectedCourseId != null
                      ? _buildCourseStatistics(
                          _selectedCourseId!,
                          _selectedCourseName,
                          isDarkMode,
                        )
                      : _buildEmptyState(isDarkMode, '请选择要查看的课程'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatistics(
    String courseId,
    String? courseName,
    bool isDarkMode,
  ) {
    final courseStatisticsAsync = ref.watch(
      courseStatisticsProvider(
        CourseStatisticsParams(courseId: courseId, courseName: courseName),
      ),
    );

    return courseStatisticsAsync.when(
      data: (courseData) => courseData != null
          ? _buildSingleCourseContent(courseData, isDarkMode)
          : _buildEmptyState(isDarkMode, '暂无统计数据'),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error, isDarkMode),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedCourseName != null
                  ? '$_selectedCourseName - 统计数字'
                  : '统计数字',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(bool isDarkMode) {
    final selectedSemester = ref.watch(selectedSemesterProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSemesterPicker(isDarkMode),
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
                selectedSemester.displayName,
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

  Widget _buildCourseSelector(
    AsyncValue<List<CourseInfo>> coursesAsync,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '该学期暂无课程数据',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 检查当前选择的课程是否在新的课程列表中
          if (_selectedCourseId != null &&
              !courses.any((course) => course.id == _selectedCourseId)) {
            // 如果当前选择的课程不在新的学期中
            if (!_isInitializing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedCourseId = courses.first.id;
                    _selectedCourseName = courses.first.name;
                  });
                }
              });
            }
          } else if (_selectedCourseId == null && courses.isNotEmpty) {
            // 如果没有选择课程，选择第一个
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedCourseId = courses.first.id;
                  _selectedCourseName = courses.first.name;
                });
              }
            });
          }

          return Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final isSelected = course.id == _selectedCourseId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCourseId = course.id;
                      _selectedCourseName = course.name;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        course.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade800.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade800.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '加载课程列表失败',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleCourseContent(
    CourseStatisticsData course,
    bool isDarkMode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 课程信息卡片
          _buildCourseInfoCard(course, isDarkMode),
          const SizedBox(height: 16),
          // 百分制成绩分布
          _buildChartSection(
            title: '百分制成绩分布',
            chart: _buildPercentageChart(course, isDarkMode),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          // 等级制成绩分布
          _buildChartSection(
            title: '等级制成绩分布',
            chart: _buildGradeChart(course, isDarkMode),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(CourseStatisticsData course, bool isDarkMode) {
    final personalScore = _getPersonalScore(course.courseId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.courseName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '通过率：${(course.passRate * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Text(
                '平均分：${course.averageGrade.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          // 显示个人成绩（如有）
          if (personalScore != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '我的成绩：${personalScore.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required Widget chart,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade800.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: chart,
        ),
      ],
    );
  }

  Widget _buildPercentageChart(CourseStatisticsData course, bool isDarkMode) {
    if (course.scoreDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 计算总人数
    final totalStudents = course.scoreDistribution.values.fold(
      0,
      (a, b) => a + b,
    );

    // 获取个人成绩用于标注
    final personalScore = _getPersonalScore(course.courseId);

    // 将人数转换为百分比并创建柱状图数据
    final barGroups = <BarChartGroupData>[];
    final sortedEntries = course.scoreDistribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage = totalStudents > 0
          ? (entry.value / totalStudents) * 100
          : 0.0;

      // 检查是否是个人成绩所在的分数段
      final isPersonalScore =
          personalScore != null && entry.key == personalScore.toInt();

      barGroups.add(
        BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: isPersonalScore
                  ? Colors
                        .red // 个人成绩用红色标注
                  : Theme.of(context).primaryColor,
              width: 8, // 调整柱子宽度，保持适当间距
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround, // 柱子周围留空间
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                isDarkMode ? Colors.grey.shade800 : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // 找到对应的分数
              final score = sortedEntries[groupIndex].key;
              return BarTooltipItem(
                '分数: $score\n百分比: ${rod.toY.toStringAsFixed(2)}%',
                TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // 只显示有数据的分数点
                final hasData = sortedEntries.any(
                  (entry) => entry.key == value.toInt(),
                );
                if (!hasData) return const SizedBox.shrink();

                // 智能间隔显示：数据点太多时跳过某些标签
                final valueInt = value.toInt();
                if (sortedEntries.length > 15) {
                  // 数据点很多时，只显示能被5整除的分数
                  if (valueInt % 5 != 0 &&
                      valueInt != sortedEntries.first.key &&
                      valueInt != sortedEntries.last.key) {
                    return const SizedBox.shrink();
                  }
                } else if (sortedEntries.length > 8) {
                  // 数据点较多时，只显示能被2整除的分数
                  if (valueInt % 2 != 0 &&
                      valueInt != sortedEntries.first.key &&
                      valueInt != sortedEntries.last.key) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Transform.rotate(
                    angle: sortedEntries.length > 12 ? -0.3 : 0, // 轻微倾斜
                    child: Text(
                      valueInt.toString(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: sortedEntries.length > 12 ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.white24 : Colors.black12,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: isDarkMode ? Colors.white24 : Colors.black12,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0, // 确保y轴最小值为0，避免负值
        maxY: null, // 让图表自动计算最大值
      ),
    );
  }

  Widget _buildGradeChart(CourseStatisticsData course, bool isDarkMode) {
    final gradeRanges = ['0-59', '60-69', '70-79', '80-89', '90-100'];
    final gradeCounts = [0.0, 0.0, 0.0, 0.0, 0.0];

    // 计算各等级段的人数
    course.scoreDistribution.forEach((score, count) {
      if (score < 60) {
        gradeCounts[0] += count.toDouble();
      } else if (score < 70) {
        gradeCounts[1] += count.toDouble();
      } else if (score < 80) {
        gradeCounts[2] += count.toDouble();
      } else if (score < 90) {
        gradeCounts[3] += count.toDouble();
      } else {
        gradeCounts[4] += count.toDouble();
      }
    });

    // 计算总人数
    final totalStudents = gradeCounts.fold(0.0, (a, b) => a + b);

    // 获取个人成绩用于标注
    final personalScore = _getPersonalScore(course.courseId);

    // 转换为百分比
    final gradePercentages = gradeCounts
        .map((count) => totalStudents > 0 ? (count / totalStudents) * 100 : 0.0)
        .toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly, // 等级制图表柱子均匀分布
        barGroups: gradePercentages.asMap().entries.map((entry) {
          final index = entry.key;
          final percentage = entry.value;

          // 检查个人成绩是否在这个等级段
          bool isPersonalGrade = false;
          if (personalScore != null) {
            final score = personalScore;
            if ((index == 0 && score < 60) ||
                (index == 1 && score >= 60 && score < 70) ||
                (index == 2 && score >= 70 && score < 80) ||
                (index == 3 && score >= 80 && score < 90) ||
                (index == 4 && score >= 90)) {
              isPersonalGrade = true;
            }
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: percentage,
                color: isPersonalGrade
                    ? Colors
                          .red // 个人成绩所在等级段用红色标注
                    : Theme.of(context).primaryColor,
                width: 24, // 调整等级制图表柱子宽度
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                isDarkMode ? Colors.grey.shade800 : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)}%',
                TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= gradeRanges.length) {
                  return const Text('');
                }
                return Text(
                  gradeRanges[index],
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.white24 : Colors.black12,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0, // 确保y轴最小值为0，避免负值
        maxY: null, // 让图表自动计算最大值
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, [String? message]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: isDarkMode ? Colors.white54 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? '暂无统计数据',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDarkMode ? Colors.white54 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // 重新加载当前课程的统计数据
              if (widget.kch != null) {
                ref.invalidate(
                  courseStatisticsProvider(
                    CourseStatisticsParams(
                      courseId: widget.kch!,
                      courseName: widget.courseName,
                    ),
                  ),
                );
              }
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showSemesterPicker(bool isDarkMode) {
    final selectedSemester = ref.read(selectedSemesterProvider);
    final availableSemesters = ref.read(availableSemestersProvider);
    final currentTheme = ref.read(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Theme.of(context).primaryColor;

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
                      semester.xnm == selectedSemester.xnm &&
                      semester.xqm == selectedSemester.xqm;

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
                      ref.read(selectedSemesterProvider.notifier).state =
                          semester;
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
}
