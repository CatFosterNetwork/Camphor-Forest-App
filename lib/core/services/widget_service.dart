import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../pages/classtable/models/course.dart';

/// 小组件服务
/// 负责更新主屏幕小组件的数据
class WidgetService {
  static const String _widgetName = 'ClassTableWidget';
  static const String _androidWidgetName = 'ClassTableWidgetProvider';
  static const String _appGroupId = 'group.social.swu.camphor_forest';

  /// 更新课表小组件
  /// 传入当前周的课程列表
  static Future<void> updateClassTableWidget({
    required List<Course> courses,
    required int currentWeek,
    required DateTime semesterStart,
  }) async {
    try {
      debugPrint('🔄 开始更新课表小组件...');

      // 设置 App Group ID（iOS）
      await HomeWidget.setAppGroupId(_appGroupId);

      // 计算今天是周几（周一=1, 周五=5）
      final now = DateTime.now();
      final weekday = now.weekday; // 1=Monday, 7=Sunday

      // 只显示周一到周五，周六周日显示周一的数据
      final displayWeekday = weekday;

      // 获取本周所有课程（周一到周日，1-14节）
      final Map<String, List<Map<String, String>>> weekData = {};

      // 生成周一到周日的数据
      for (int day = 1; day <= 7; day++) {
        final dayCourses = courses.where((course) {
          return course.weekday == day &&
              course.start >= 1 &&
              course.start <= 14;
        }).toList();

        final dayCoursesData = dayCourses.map((course) {
          return {
            'name': course.title,
            'location': course.classroom,
            'startSection': course.start.toString(),
            'endSection': course.end.toString(),
            'teacher': course.teacher,
            'weekday': course.weekday.toString(),
          };
        }).toList();

        weekData['day_$day'] = dayCoursesData;
      }

      // 保存数据到小组件
      final jsonData = json.encode(weekData);
      await HomeWidget.saveWidgetData<String>('class_table_data', jsonData);
      await HomeWidget.saveWidgetData<int>('current_week', currentWeek);
      await HomeWidget.saveWidgetData<int>('current_weekday', displayWeekday);
      await HomeWidget.saveWidgetData<String>('update_time', now.toString());

      // 更新小组件
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidWidgetName,
      );

      debugPrint('✅ 课表小组件更新成功');
      debugPrint('   - 当前周次: $currentWeek');
      debugPrint('   - 当前星期: $displayWeekday');
      debugPrint('   - 总课程数: ${courses.length}');
      debugPrint(
        '   - 周一到周日课程数: ${weekData.values.map((e) => e.length).join(', ')}',
      );
      debugPrint('   - JSON数据长度: ${jsonData.length} 字符');

      // 打印每天的课程详情用于调试
      for (var day = 1; day <= 7; day++) {
        final dayCourses = weekData['day_$day'];
        if (dayCourses != null && dayCourses.isNotEmpty) {
          debugPrint(
            '   - 周$day: ${dayCourses.map((c) => c['name']).join(', ')}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 更新课表小组件失败: $e');
    }
  }

  /// 清空课表小组件数据
  static Future<void> clearClassTableWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('class_table_data', '{}');
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidWidgetName,
      );
      debugPrint('✅ 课表小组件数据已清空');
    } catch (e) {
      debugPrint('❌ 清空课表小组件数据失败: $e');
    }
  }
}
