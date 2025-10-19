import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pages/classtable/providers/classtable_providers.dart';
import '../../pages/classtable/providers/classtable_settings_provider.dart';
import '../../pages/classtable/constants/semester.dart';
import '../../pages/classtable/models/course.dart';
import '../providers/auth_provider.dart';
import 'widget_service.dart';

/// 小组件自动更新监听器
/// 负责监听课表数据变化并自动更新小组件
class WidgetUpdateListener {
  /// 设置全局监听器
  static void setupListeners(WidgetRef ref) {
    // 监听课表设置变化
    ref.listen<ClassTableSettingsState>(classTableSettingsProvider, (
      previous,
      next,
    ) {
      // 当学期切换时，尝试更新小组件
      if (previous?.currentXnm != next.currentXnm ||
          previous?.currentXqm != next.currentXqm) {
        AppLogger.debug('🔔 检测到学期切换，准备更新小组件');
        _updateWidget(ref, next.currentXnm, next.currentXqm);
      }
    });

    // 监听认证状态变化
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (next) {
        // 登录后尝试更新小组件
        AppLogger.debug('🔔 检测到用户登录，准备更新小组件');
        final settings = ref.read(classTableSettingsProvider);
        _updateWidget(ref, settings.currentXnm, settings.currentXqm);
      } else {
        // 退出登录时清空小组件
        AppLogger.debug('🔔 检测到用户登出，清空小组件');
        WidgetService.clearClassTableWidget();
      }
    });
  }

  /// 更新小组件数据
  static Future<void> _updateWidget(
    WidgetRef ref,
    String xnm,
    String xqm,
  ) async {
    try {
      // 检查是否已登录
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (!isAuthenticated) {
        AppLogger.debug('🔔 用户未登录，跳过小组件更新');
        return;
      }

      if (xnm.isEmpty || xqm.isEmpty) {
        AppLogger.debug('🔔 学期参数为空，跳过小组件更新');
        return;
      }

      // 读取缓存的课表数据
      final classTableRepo = ref.read(classTableRepositoryProvider);
      final classTable = await classTableRepo.loadLocal(xnm, xqm);

      if (classTable == null) {
        AppLogger.debug('🔔 没有缓存的课表数据，跳过小组件更新');
        return;
      }

      // 计算当前周次
      final semesterStart = SemesterConfig.getSemesterStart(xnm, xqm);
      final now = DateTime.now();
      final daysSinceStart = now.difference(semesterStart).inDays;
      final currentWeek = (daysSinceStart / 7).floor() + 1;

      // 获取当前周的课程
      final weekCourses = classTable.weekTable[currentWeek];
      if (weekCourses == null || weekCourses.isEmpty) {
        AppLogger.debug('🔔 本周没有课程数据，跳过小组件更新');
        return;
      }

      // 合并所有课程到一个列表
      final allCourses = <Course>[];
      weekCourses.forEach((weekday, courses) {
        allCourses.addAll(courses);
      });

      if (allCourses.isEmpty) {
        AppLogger.debug('🔔 本周课程列表为空，跳过小组件更新');
        return;
      }

      // 更新小组件
      AppLogger.debug('🔔 自动更新小组件数据');
      await WidgetService.updateClassTableWidget(
        courses: allCourses,
        currentWeek: currentWeek,
        semesterStart: semesterStart,
      );
      AppLogger.debug('✅ 小组件数据更新成功');
    } catch (e) {
      AppLogger.debug('❌ 更新小组件数据失败: $e');
    }
  }

  /// 手动触发小组件更新（用于app启动时）
  static Future<void> triggerUpdate(WidgetRef ref) async {
    final settings = ref.read(classTableSettingsProvider);
    await _updateWidget(ref, settings.currentXnm, settings.currentXqm);
  }
}
