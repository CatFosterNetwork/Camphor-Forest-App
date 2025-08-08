import 'package:flutter/material.dart';
import '../models/course.dart';
import '../constants/period_times.dart';
import '../../../core/models/theme_model.dart' as CustomTheme;

class ClassTableChart extends StatelessWidget {
  final List<Course> courses;
  final bool darkMode;
  final int currentWeek;
  final DateTime semesterStart;
  
  // 新增主题配置支持
  final CustomTheme.Theme? customTheme;

  // 新增交互回调
  final void Function(Course course, Rect courseRect)? onCourseTap;

  const ClassTableChart({
    super.key,
    required this.courses,
    required this.darkMode,
    required this.currentWeek,
    required this.semesterStart,
    this.customTheme,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 创建颜色映射表以区分不同课程
    final courseColors = _createCourseColors(courses, scheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final headerHeight = 48.0;
        final bodyHeight = totalHeight - headerHeight;
        final periodCount = PeriodTimes.times.length;

        // 确保单元格高度是整数，并且留出足够的空间，避免溢出
        // 减去1像素的安全边界
        final cellHeight = (bodyHeight / periodCount).floor() - 1.0;

        // 创建网格系统
        return Column(
          children: [
            _buildDateHeader(headerHeight),
            Expanded(
              child: Row(
                children: [
                  _buildTimeColumn(cellHeight),
                  Expanded(
                    child: _buildCourseGrid(
                      cellHeight: cellHeight,
                      gridWidth: constraints.maxWidth - 40,
                      courseColors: courseColors,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 提取日期头部为独立方法，提高可读性
  Widget _buildDateHeader(double height) {
    final monday = semesterStart.add(Duration(days: (currentWeek - 1) * 7));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    
    final headerTextColor = darkMode 
        ? const Color(0xFFBFC2C9)
        : (customTheme?.weekColor ?? Colors.black87);
    final today = DateTime.now();

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                "${monday.month}月",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: headerTextColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: days.map((day) {
                final isToday =
                    day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;
                final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

                return Expanded(
                  child: Container(
                    decoration: isToday
                        ? BoxDecoration(
                            border: Border.all(
                              color: darkMode ? Colors.white60 : Colors.black54,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '周${weekdayNames[day.weekday - 1]}',
                          style: TextStyle(
                            color: headerTextColor,
                            fontWeight: isToday ? FontWeight.bold : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: headerTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 提取时间列为独立方法
  Widget _buildTimeColumn(double cellHeight) {
    final timeTextColor = darkMode 
        ? const Color(0xFFBFC2C9)
        : (customTheme?.foregColor.withAlpha(204) ?? Colors.black54);

    return SizedBox(
      width: 40,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: PeriodTimes.times.length,
        itemBuilder: (context, index) {
          final periodIndex = index + 1;
          final period = PeriodTimes.times[periodIndex]!;

          return SizedBox(
            height: cellHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$periodIndex',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: timeTextColor,
                    ),
                  ),
                  Text(
                    period.begin,
                    style: TextStyle(fontSize: 9, color: timeTextColor),
                  ),
                  Text(
                    period.end,
                    style: TextStyle(fontSize: 9, color: timeTextColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 核心方法：创建课程网格
  Widget _buildCourseGrid({
    required double cellHeight,
    required double gridWidth,
    required Map<String, Color> courseColors,
  }) {
    // 对课程按周几进行分组
    final coursesByDay = <int, List<Course>>{};

    for (final course in courses) {
      coursesByDay.putIfAbsent(course.weekday, () => []).add(course);
    }

    // 计算单元格宽度
    final cellWidth = gridWidth / 7;

    return Stack(
      children: [
        // 1. 绘制背景网格
        _buildGridBackground(cellHeight),

        // 2. 添加课程卡片
        for (int weekday = 1; weekday <= 7; weekday++)
          if (coursesByDay.containsKey(weekday))
            ..._buildCoursesForDay(
              courses: coursesByDay[weekday]!,
              weekday: weekday,
              cellWidth: cellWidth,
              cellHeight: cellHeight,
              courseColors: courseColors,
            ),
      ],
    );
  }

  // 绘制背景网格
  Widget _buildGridBackground(double cellHeight) {
    // 根据自定义主题和深色模式调整网格颜色
    final Color gridColor;
    if (customTheme != null) {
      // 如果有自定义主题，使用前景色作为网格颜色基础
      gridColor = darkMode 
          ? customTheme!.foregColor.withAlpha(26)
          : customTheme!.foregColor.withAlpha(15);
    } else {
      // 没有自定义主题时使用默认颜色
      gridColor = darkMode
          ? Colors.white.withAlpha(20)
          : Colors.black.withAlpha(13);
    }

    final totalGridHeight = cellHeight * PeriodTimes.times.length;

    return SizedBox(
      height: totalGridHeight,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: PeriodTimes.times.length,
        itemBuilder: (context, index) {
          return SizedBox(
            height: cellHeight,
            child: Row(
              children: List.generate(
                7,
                (dayIndex) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: gridColor, width: 0.5),
                        right: BorderSide(color: gridColor, width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 为某一天创建课程卡片
  List<Widget> _buildCoursesForDay({
    required List<Course> courses,
    required int weekday,
    required double cellWidth,
    required double cellHeight,
    required Map<String, Color> courseColors,
  }) {
    if (courses.isEmpty) return [];

    // 按课程开始节次排序
    courses.sort((a, b) => a.start.compareTo(b.start));

    // 处理同一时间段的课程，生成占位信息
    final coursePlacements = _calculateCoursePlacements(courses);

    return courses.asMap().entries.map((entry) {
      final index = entry.key;
      final course = entry.value;
      final placement = coursePlacements[index];

      // 计算位置和尺寸
      final left =
          (weekday - 1) * cellWidth + placement.offsetRatio * cellWidth;
      final top = (course.start - 1) * cellHeight;
      final width = cellWidth * placement.widthRatio - 4; // 留出间距
      final height = (course.end - course.start + 1) * cellHeight - 2;

      // 使用缓存构建课程卡片，提高性能
      return Positioned(
        left: left + 2,
        top: top + 1,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onCourseTap != null ? () {
            final courseRect = Rect.fromLTWH(left + 2, top + 1, width, height);
            onCourseTap!(course, courseRect);
          } : null,
          child: Hero(
            tag: 'course_${course.id}_${course.weekday}_${course.start}',
            child: _CourseCard(
              course: course,
              color: courseColors[course.id] ?? Colors.blue,
              darkMode: darkMode,
            ),
          ),
        ),
      );
    }).toList();
  }

  // 计算课程在同一时间段的布局
  List<_CoursePlacement> _calculateCoursePlacements(List<Course> courses) {
    if (courses.isEmpty) return [];

    final result = <_CoursePlacement>[];

    // 创建时间占用表
    final timeSlots = <int, List<int>>{};

    for (int i = 0; i < courses.length; i++) {
      final course = courses[i];
      final slots = <int>[];

      // 为课程每一节课都找到可用的时间槽
      for (int period = course.start; period <= course.end; period++) {
        timeSlots.putIfAbsent(period, () => []);
        slots.add(timeSlots[period]!.length);
        timeSlots[period]!.add(i);
      }

      // 确定课程所在的列和宽度
      int maxSlot = slots.isEmpty ? 0 : slots.reduce((a, b) => a > b ? a : b);
      int totalSlots = slots.isEmpty ? 1 : timeSlots[course.start]!.length;

      result.add(
        _CoursePlacement(
          offsetRatio: maxSlot / totalSlots,
          widthRatio: 1.0 / totalSlots,
        ),
      );
    }

    return result;
  }

  // 为不同课程创建不同颜色，适配深色模式
  Map<String, Color> _createCourseColors(
    List<Course> courses,
    ColorScheme scheme,
  ) {
    // 提取所有独特的课程ID
    final uniqueCourseIds = courses.map((c) => c.id).toSet().toList();

    // 深色模式下使用统一的深色背景
    if (darkMode) {
      final darkBackground = const Color(0xFF202125);
      final Map<String, Color> colorMap = {};
      for (final courseId in uniqueCourseIds) {
        colorMap[courseId] = darkBackground;
      }
      return colorMap;
    }

    // 浅色模式下使用自定义主题的颜色列表
    final List<Color> baseColors;
    if (customTheme?.colorList.isNotEmpty == true) {
      baseColors = customTheme!.colorList;
    } else {
      baseColors = [
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        Colors.purple,
        Colors.teal,
        Colors.amber.shade800,
        Colors.indigo,
        Colors.pink,
        Colors.green,
        Colors.deepOrange,
      ];
    }

    // 映射课程ID到颜色
    final Map<String, Color> colorMap = {};
    for (int i = 0; i < uniqueCourseIds.length; i++) {
      final courseId = uniqueCourseIds[i];
      // 使用课程ID的字符码和来选择颜色
      final colorIndex = courseId.codeUnits.fold(0, (sum, code) => sum + code) % baseColors.length;
      final color = baseColors[colorIndex];
      
      colorMap[courseId] = color;
    }

    return colorMap;
  }
}

// 课程位置计算辅助类
class _CoursePlacement {
  // 水平偏移比例
  final double offsetRatio;
  // 宽度比例
  final double widthRatio;

  const _CoursePlacement({required this.offsetRatio, required this.widthRatio});
}

// 课程卡片组件，适配深色模式
class _CourseCard extends StatelessWidget {
  final Course course;
  final Color color;
  final bool darkMode;

  const _CourseCard({
    required this.course,
    required this.color,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        // 深色模式下添加边框
        border: darkMode ? Border.all(
          color: const Color(0xFF616266),
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.black12,
            blurRadius: darkMode ? 3 : 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
          const Spacer(),
          if (course.classroom.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                course.classroom,
                maxLines: 2, // 允许两行显示
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8, 
                  color: _getTextColor().withAlpha(230),
                  height: 1.1, // 减小行高以节省空间
                ),
              ),
            ),
          if (course.teacher.isNotEmpty)
            Text(
              course.teacher,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9, 
                color: _getTextColor().withAlpha(230)
              ),
            ),
        ],
      ),
    );
  }
  
  // 获取文本颜色，适配深色模式
  Color _getTextColor() {
    if (darkMode) {
      return const Color(0xFFBFC2C9);
    } else {
      // 浅色模式下根据背景颜色自动计算最佳文本颜色
      final brightness = color.computeLuminance();
      return brightness > 0.5 ? Colors.black87 : Colors.white;
    }
  }
}
