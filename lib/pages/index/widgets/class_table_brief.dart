import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/providers/grade_provider.dart';
import '../../classtable/providers/classtable_providers.dart';
import '../../classtable/constants/period_times.dart';
import '../../classtable/constants/semester.dart';
import '../../classtable/models/course.dart';

/// 主页课表简要组件
class ClassTableBrief extends ConsumerWidget {
  final bool blur;
  final bool darkMode;

  const ClassTableBrief({
    super.key,
    required this.blur,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xnm = GradeNotifier.getCurrentXnm();
    final xqm = GradeNotifier.getCurrentSemester();

    final tableAsync = ref.watch(classTableProvider((xnm: xnm, xqm: xqm)));

    final DateTime currentTime = DateTime.now();
    final int currentDay = currentTime.weekday; // 1~7

    // 计算当前周次
    final diffDays = currentTime.difference(SemesterConfig.start).inDays;
    final currentWeek = (diffDays ~/ 7) + 1;

    return GestureDetector(
      onTap: () => context.push(RouteConstants.classTable),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        child: _applyContainerStyle(
          _buildContent(tableAsync, currentTime, currentDay, currentWeek),
        ),
      ),
    );
  }

  /// 应用容器样式和模糊效果
  /// 完全复制todo_brief的样式逻辑以保持一致性
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

  /// 构建内容区域
  Widget _buildContent(
    AsyncValue tableAsync,
    DateTime currentTime,
    int currentDay,
    int currentWeek,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: tableAsync.when(
        loading: () => _buildLoadingState(currentTime, currentDay),
        error: (e, _) => _buildErrorState(currentTime, currentDay),
        data: (table) {
          final weekSchedule = table.getWeekSchedule(currentWeek);
          final List<Course> todayCourses;

          if (weekSchedule != null && weekSchedule.containsKey(currentDay)) {
            todayCourses = weekSchedule[currentDay] ?? [];
            todayCourses.sort(
              (a, b) => a.periods.first.compareTo(b.periods.first),
            );
          } else {
            todayCourses = [];
          }

          return _buildCourseContent(currentTime, currentDay, todayCourses);
        },
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(DateTime currentTime, int currentDay) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(currentTime, currentDay, null),
        const SizedBox(height: 16),
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              darkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(DateTime currentTime, int currentDay) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(currentTime, currentDay, null),
        const SizedBox(height: 20),
        Text(
          '加载失败',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '点击重试',
          style: TextStyle(
            fontSize: 14,
            color: darkMode ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 构建课程内容
  Widget _buildCourseContent(
    DateTime currentTime,
    int currentDay,
    List<Course> courses,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(currentTime, currentDay, courses),
        const SizedBox(height: 6),

        if (courses.isNotEmpty)
          _buildCourseList(courses)
        else
          _buildNoCourseState(),
      ],
    );
  }

  /// 构建头部信息（时间、星期、课程指示器）
  Widget _buildHeader(
    DateTime currentTime,
    int currentDay,
    List<Course>? courses,
  ) {
    final textColor = darkMode ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 日期
        Text(
          '${currentTime.month}月${currentTime.day}日',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 星期
        Text(
          _getWeekdayText(currentDay),
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 课程状态指示器（小球）
        if (courses != null && courses.isNotEmpty)
          _buildCourseIndicators(courses),
      ],
    );
  }

  /// 构建课程状态指示器
  Widget _buildCourseIndicators(List<Course> courses) {
    final currentPeriod = _getCurrentPeriodIndex();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(courses.length, (index) {
        final isActive = _isCourseActive(courses[index], currentPeriod);
        return Container(
          margin: const EdgeInsets.only(left: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.green.withAlpha(153)
                : Colors.grey.withAlpha(102),
          ),
        );
      }),
    );
  }

  /// 构建课程列表
  Widget _buildCourseList(List<Course> courses) {
    final currentPeriod = _getCurrentPeriodIndex();

    return Column(
      children: courses.map((course) {
        final isActive = _isCourseActive(course, currentPeriod);
        final isPast = _isCoursePast(course, currentPeriod);

        return _buildCourseItem(course, isActive, isPast);
      }).toList(),
    );
  }

  /// 构建单个课程项
  Widget _buildCourseItem(Course course, bool isActive, bool isPast) {
    final textColor = darkMode ? Colors.white : Colors.black87;
    final fadedColor = darkMode
        ? const Color(0xFF9d9fa2)
        : Colors.grey.shade500;

    final periods = course.periods;
    final startPeriod = periods.isNotEmpty ? periods.first : 1;
    final endPeriod = periods.isNotEmpty ? periods.last : startPeriod;

    final startTime = PeriodTimes.times[startPeriod]?.begin ?? '';
    final endTime = PeriodTimes.times[endPeriod]?.end ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 课程名称 - 左对齐，占2/3宽度
          Expanded(
            flex: 2,
            child: Text(
              course.title,
              style: TextStyle(
                color: isPast ? fadedColor : textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start, // 明确左对齐
            ),
          ),

          // 状态指示线
          Container(
            width: 2,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? Colors.green.withAlpha(153)
                  : Colors.grey.withAlpha(102),
            ),
          ),

          // 时间和地点 - 居中对齐，占1/3宽度
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$startTime-$endTime',
                  style: TextStyle(
                    color: isPast ? fadedColor : textColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  course.classroom,
                  style: TextStyle(
                    color: isPast ? fadedColor : textColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建无课状态
  Widget _buildNoCourseState() {
    final statusColor = darkMode
        ? const Color(0xFF9d9fa2)
        : Colors.grey.shade500;
    final subtitleColor = darkMode
        ? const Color(0xFF9d9fa2)
        : Colors.grey.shade500;
    final textColor = darkMode ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '今天没课啦',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('好好休息吧', style: TextStyle(fontSize: 14, color: subtitleColor)),
            const SizedBox(height: 16),
            Text(
              '明天的课会在24:00更新',
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取当前节次
  int _getCurrentPeriodIndex() {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (int i = 1; i <= PeriodTimes.times.length; i++) {
      final period = PeriodTimes.times[i]!;
      final endTimeParts = period.end.split(':');
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);
      final endMinutes = endHour * 60 + endMinute;

      if (currentMinutes <= endMinutes) {
        return i;
      }
    }

    return -1; // 所有课程都已结束
  }

  /// 判断课程是否活跃（当前或未来）
  bool _isCourseActive(Course course, int currentPeriod) {
    if (currentPeriod == -1) return false; // 一天课程已结束

    final startPeriod = course.periods.isNotEmpty ? course.periods.first : 1;
    return currentPeriod <= startPeriod;
  }

  /// 判断课程是否已过
  bool _isCoursePast(Course course, int currentPeriod) {
    if (currentPeriod == -1) return true; // 一天课程已结束

    final endPeriod = course.periods.isNotEmpty ? course.periods.last : 1;
    return currentPeriod > endPeriod;
  }

  /// 转换星期几文本
  String _getWeekdayText(int weekday) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekday >= 1 && weekday <= 7 ? weekdays[weekday - 1] : '未知'}';
  }
}
