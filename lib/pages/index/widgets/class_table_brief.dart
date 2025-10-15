import 'dart:async';
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
class ClassTableBrief extends ConsumerStatefulWidget {
  final bool blur;
  final bool darkMode;

  const ClassTableBrief({
    super.key,
    required this.blur,
    required this.darkMode,
  });

  @override
  ConsumerState<ClassTableBrief> createState() => _ClassTableBriefState();
}

class _ClassTableBriefState extends ConsumerState<ClassTableBrief> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// 启动定时器，每分钟更新一次
  void _startUpdateTimer() {
    // 计算到下一分钟的秒数
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;

    // 先等到下一分钟整点
    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      if (mounted) {
        setState(() {}); // 触发重建
        // 然后每分钟更新一次
        _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          if (mounted) {
            setState(() {}); // 触发重建
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              widget.darkMode ? Colors.white70 : Colors.black54,
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
            color: widget.darkMode
                ? Colors.grey.shade400
                : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '点击重试',
          style: TextStyle(
            fontSize: 14,
            color: widget.darkMode
                ? Colors.grey.shade500
                : Colors.grey.shade500,
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
    final textColor = widget.darkMode ? Colors.white : Colors.black87;

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
    final textColor = widget.darkMode ? Colors.white : Colors.black87;
    final fadedColor = widget.darkMode
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

          // 状态指示线（百分比条）
          _buildCourseIndicator(course, isActive, isPast),

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

  /// 构建课程指示器（百分比条）
  Widget _buildCourseIndicator(Course course, bool isActive, bool isPast) {
    // 判断是否正在上课
    final isOngoing = _isCourseOngoing(course);

    if (isOngoing) {
      // 正在上课：显示百分比进度条
      final progress = _getCourseProgress(course);
      return Container(
        width: 2,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // 已过去部分（灰色）
            Expanded(
              flex: (progress * 100).toInt(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.withAlpha(102),
                ),
              ),
            ),
            // 剩余部分（绿色）
            Expanded(
              flex: ((1 - progress) * 100).toInt(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  color: Colors.green.withAlpha(153),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 未开始或已结束：显示单色指示线
      return Container(
        width: 2,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? Colors.green.withAlpha(153)
              : Colors.grey.withAlpha(102),
        ),
      );
    }
  }

  /// 构建无课状态
  Widget _buildNoCourseState() {
    final statusColor = widget.darkMode
        ? const Color(0xFF9d9fa2)
        : Colors.grey.shade500;
    final subtitleColor = widget.darkMode
        ? const Color(0xFF9d9fa2)
        : Colors.grey.shade500;
    final textColor = widget.darkMode ? Colors.white70 : Colors.black87;

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

    final endPeriod = course.periods.isNotEmpty ? course.periods.last : 1;
    return currentPeriod <= endPeriod;
  }

  /// 判断课程是否已过
  bool _isCoursePast(Course course, int currentPeriod) {
    if (currentPeriod == -1) return true; // 一天课程已结束

    final endPeriod = course.periods.isNotEmpty ? course.periods.last : 1;
    return currentPeriod > endPeriod;
  }

  /// 判断课程是否正在进行中（已开始但未结束）
  bool _isCourseOngoing(Course course) {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final periods = course.periods;
    if (periods.isEmpty) return false;

    final startPeriod = periods.first;
    final endPeriod = periods.last;

    // 获取开始和结束时间
    final startTime = PeriodTimes.times[startPeriod];
    final endTime = PeriodTimes.times[endPeriod];

    if (startTime == null || endTime == null) return false;

    final startParts = startTime.begin.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = endTime.end.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // 当前时间在课程时间段内
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  /// 获取课程进度百分比（0.0 - 1.0）
  double _getCourseProgress(Course course) {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final periods = course.periods;
    if (periods.isEmpty) return 0.0;

    final startPeriod = periods.first;
    final endPeriod = periods.last;

    final startTime = PeriodTimes.times[startPeriod];
    final endTime = PeriodTimes.times[endPeriod];

    if (startTime == null || endTime == null) return 0.0;

    final startParts = startTime.begin.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = endTime.end.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final totalMinutes = endMinutes - startMinutes;
    if (totalMinutes <= 0) return 0.0;

    final elapsedMinutes = currentMinutes - startMinutes;
    final progress = elapsedMinutes / totalMinutes;

    // 确保在 0.0 - 1.0 范围内
    return progress.clamp(0.0, 1.0);
  }

  /// 转换星期几文本
  String _getWeekdayText(int weekday) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekday >= 1 && weekday <= 7 ? weekdays[weekday - 1] : '未知'}';
  }
}
