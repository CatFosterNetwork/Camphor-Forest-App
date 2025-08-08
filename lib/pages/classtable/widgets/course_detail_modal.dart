import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/course.dart';

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
    
    // 目标位置和大小 - 减小modal大小
    final targetRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: screenSize.width - 80, // 增加边距
      height: math.min(400, screenSize.height - 200), // 限制最大高度
    );
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // 背景透明度动画
          final backgroundOpacity = Curves.easeOut.transform(animation.value) * 0.54;
          
          // 位置和大小插值
          final currentRect = Rect.lerp(sourceRect, targetRect, Curves.easeOutCubic.transform(animation.value))!;
          
          // 圆角半径动画
          final borderRadius = Tween<double>(begin: 6.0, end: 16.0).transform(Curves.easeOut.transform(animation.value));
          
          return Stack(
            children: [
              // 背景遮罩
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withAlpha((backgroundOpacity * 255).round()),
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
                        color: isDarkMode ? const Color(0xFF202125) : Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * animation.value * 255).round()),
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
        border: isDarkMode ? Border.all(
          color: const Color(0xFF616266),
          width: 1,
        ) : null,
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
                color: _getTextColor(courseColor).withAlpha(230)
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedContent(BuildContext context, double detailAnimationValue) {
    return Opacity(
      opacity: detailAnimationValue,
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
          
          // 详情内容 - 更紧凑
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactDetailItem('课程代码', course.id, Icons.code),
                  if (course.classroom.isNotEmpty)
                    _buildCompactDetailItem('上课教室', course.classroom, Icons.location_on),
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
                child: Text(
                  '关闭',
                  style: TextStyle(color: _getButtonColor()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2), // 向下微调图标位置以对齐文本中心
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: courseColor.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: courseColor,
            ),
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