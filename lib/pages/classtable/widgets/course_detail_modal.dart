import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../../../core/constants/route_constants.dart';

class CourseDetailModal extends StatelessWidget {
  final Course course;
  final bool isDarkMode;
  final Color courseColor;
  final Rect sourceRect;
  final Animation<double> animation;

  const CourseDetailModal({
    super.key,
    required this.course,
    required this.isDarkMode,
    required this.courseColor,
    required this.sourceRect,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 目标位置和大小
    final targetRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: screenSize.width - 80, // 增加边距
      height: math.min(
        screenSize.height * 0.6,
        screenSize.height - 200,
      ), // 最大高度为屏幕60%
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // 背景透明度动画
          final backgroundOpacity =
              Curves.easeOut.transform(animation.value) * 0.54;

          // 位置和大小插值
          final currentRect = Rect.lerp(
            sourceRect,
            targetRect,
            Curves.easeOutCubic.transform(animation.value),
          )!;

          // 圆角半径动画
          final borderRadius = Tween<double>(
            begin: 6.0,
            end: 16.0,
          ).transform(Curves.easeOut.transform(animation.value));

          return Stack(
            children: [
              // 背景遮罩
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withAlpha(
                    (backgroundOpacity * 255).round(),
                  ),
                ),
              ),

              // 课程卡片到详情的动画
              Positioned(
                left: currentRect.left,
                top: currentRect.top,
                width: currentRect.width,
                height: currentRect.height,
                child: Hero(
                  tag: 'course_${course.id}_${course.weekday}_${course.start}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF202125)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              (0.3 * animation.value * 255).round(),
                            ),
                            blurRadius: 20 * animation.value,
                            offset: Offset(0, 10 * animation.value),
                          ),
                        ],
                      ),
                      child: _buildModalContent(context, animation.value),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModalContent(BuildContext context, double animationValue) {
    // 当动画进度小于0.5时，显示简化的课程卡片内容
    if (animationValue < 0.5) {
      return _buildSimpleCard();
    }

    // 当动画进度大于0.5时，显示详细内容
    return _buildDetailedContent(context, (animationValue - 0.5) * 2);
  }

  Widget _buildSimpleCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: courseColor,
        borderRadius: BorderRadius.circular(6),
        border: isDarkMode
            ? Border.all(color: const Color(0xFF616266), width: 1)
            : null,
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
              color: _getTextColor(courseColor),
            ),
          ),
          const Spacer(),
          if (course.classroom.isNotEmpty)
            Text(
              course.classroom,
              maxLines: 2, // 允许两行显示
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: _getTextColor(courseColor).withAlpha(230),
                height: 1.1, // 减小行高以节省空间
              ),
            ),
          if (course.teacher.isNotEmpty)
            Text(
              course.teacher,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: _getTextColor(courseColor).withAlpha(230),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedContent(
    BuildContext context,
    double detailAnimationValue,
  ) {
    final screenSize = MediaQuery.of(context).size;

    return Opacity(
      opacity: detailAnimationValue,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8, // 最大高度为屏幕80%
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部课程标题栏 - 更紧凑
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: courseColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 18, // 减小字体
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(courseColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(26),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.close,
                            color: _getTextColor(courseColor),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (course.teacher.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      course.teacher,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getTextColor(courseColor).withAlpha(230),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 详情内容 - 可滚动
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactDetailItem('课程代码', course.id, Icons.code),
                    // 显示课程属性：优先显示API的kcxz，然后是自定义的courseType
                    // 只有当属性不为空且不是纯空格时才显示
                    if (course.kcxz != null && course.kcxz!.trim().isNotEmpty)
                      _buildCourseAttributeItem('课程性质', course.kcxz!.trim()),
                    if (course.kclb != null && course.kclb!.trim().isNotEmpty)
                      _buildCourseAttributeItem('课程类别', course.kclb!.trim()),
                    if (course.courseType != null &&
                        course.courseType!.trim().isNotEmpty &&
                        (course.kcxz == null || course.kcxz!.trim().isEmpty))
                      _buildCourseAttributeItem(
                        '课程类型',
                        course.courseType!.trim(),
                      ),
                    if (course.classroom.isNotEmpty)
                      _buildCompactDetailItem(
                        '上课教室',
                        course.classroom,
                        Icons.location_on,
                      ),
                    _buildCompactDetailItem(
                      '上课时间',
                      '周${_weekdayText(course.weekday)} 第${course.periods.join(',')}节',
                      Icons.schedule,
                    ),
                    _buildCompactDetailItem(
                      '上课周次',
                      _formatWeeks(course.weeks),
                      Icons.calendar_today,
                    ),

                    // 统计数据查看按钮
                    if (!course.id.startsWith('custom_'))
                      _buildStatisticsButton(context),
                  ],
                ),
              ),
            ),

            // 底部按钮 - 更紧凑
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _getButtonColor()),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('关闭', style: TextStyle(color: _getButtonColor())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建课程属性项（带颜色，与其他详情项UI一致）
  Widget _buildCourseAttributeItem(String label, String value) {
    final typeColor = _getCourseAttributeColor(value);
    // 在深色模式下使用更明亮的图标颜色
    final iconColor = isDarkMode ? Colors.blue.shade300 : courseColor;
    final iconBackgroundColor = isDarkMode
        ? Colors.blue.shade300.withAlpha(26)
        : courseColor.withAlpha(26);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2), // 向下微调图标位置以对齐文本中心
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.school, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取课程属性对应的颜色（简化版本：只有必修课显示红色）
  Color _getCourseAttributeColor(String attribute) {
    // 检查是否为必修课相关的属性
    final requiredKeywords = ['必修', '实践', '专必', '专业必修', '专业发展'];
    if (requiredKeywords.any((keyword) => attribute.contains(keyword))) {
      return const Color(0xFFE53E3E); // 红色
    }
    return const Color(0xFF718096); // 默认灰色
  }

  Widget _buildCompactDetailItem(String label, String value, IconData icon) {
    // 在深色模式下使用更明亮的图标颜色
    final iconColor = isDarkMode ? Colors.blue.shade300 : courseColor;
    final iconBackgroundColor = isDarkMode
        ? Colors.blue.shade300.withAlpha(26)
        : courseColor.withAlpha(26);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2), // 向下微调图标位置以对齐文本中心
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据查看按钮
  Widget _buildStatisticsButton(BuildContext context) {
    // 在深色模式下使用更明亮的颜色
    final buttonColor = isDarkMode ? Colors.blue.shade300 : courseColor;
    final buttonBackgroundColor = isDarkMode
        ? Colors.blue.shade300.withAlpha(51)
        : courseColor.withAlpha(26);
    final buttonBorderColor = isDarkMode
        ? Colors.blue.shade300.withAlpha(128)
        : courseColor.withAlpha(128);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () {
          // 关闭当前模态框
          Navigator.of(context).pop();
          // 导航到统计页面，传递课程代码参数
          context.push(
            '${RouteConstants.statistics}?kch=${course.id}&courseName=${Uri.encodeComponent(course.title)}',
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: buttonBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonBorderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, color: buttonColor, size: 16),
              const SizedBox(width: 8),
              Text(
                '点此处查看课程统计数据',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 格式化周次
  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '未知';

    // 连续周次合并显示
    final List<String> parts = [];
    int start = weeks.first;
    int end = start;

    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == end + 1) {
        end = weeks[i];
      } else {
        parts.add(start == end ? '$start' : '$start-$end');
        start = end = weeks[i];
      }
    }
    parts.add(start == end ? '$start' : '$start-$end');

    return '第${parts.join(', ')}周';
  }

  // 根据星期数字返回中文
  String _weekdayText(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekday >= 1 && weekday <= 7 ? weekdays[weekday - 1] : '未知';
  }

  // 根据背景颜色获取合适的文本颜色
  Color _getTextColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }

  // 获取按钮颜色，适配深色模式
  Color _getButtonColor() {
    if (isDarkMode) {
      // 深色模式下使用浅色边框和文字，确保可见性
      return Colors.white70;
    } else {
      // 浅色模式下使用课程颜色
      return courseColor;
    }
  }
}
