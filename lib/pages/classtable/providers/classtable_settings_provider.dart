import 'dart:async';

import '../../../core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/custom_course_model.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/models/grade_models.dart';
import 'classtable_providers.dart';
import '../../../core/services/notification_service.dart';

/// 课程表设置状态
class ClassTableSettingsState {
  final List<CustomCourse> customCourses;
  final List<HistoryClassTable> historyClassTables;
  final String currentXnm;
  final String currentXqm;
  final bool isLoading;
  final String? error;

  const ClassTableSettingsState({
    this.customCourses = const [],
    this.historyClassTables = const [],
    required this.currentXnm,
    required this.currentXqm,
    this.isLoading = false,
    this.error,
  });

  ClassTableSettingsState copyWith({
    List<CustomCourse>? customCourses,
    List<HistoryClassTable>? historyClassTables,
    String? currentXnm,
    String? currentXqm,
    bool? isLoading,
    String? error,
  }) {
    return ClassTableSettingsState(
      customCourses: customCourses ?? this.customCourses,
      historyClassTables: historyClassTables ?? this.historyClassTables,
      currentXnm: currentXnm ?? this.currentXnm,
      currentXqm: currentXqm ?? this.currentXqm,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 获取当前学期显示名称
  String get currentSemesterDisplayName {
    final year = int.tryParse(currentXnm) ?? DateTime.now().year;
    if (currentXqm == '12') {
      return '${year + 1}年春季学期';
    } else if (currentXqm == '3') {
      return '$year年秋季学期';
    } else {
      return '$year年夏季学期';
    }
  }
}

/// 课程表设置状态管理器
class ClassTableSettingsNotifier
    extends StateNotifier<ClassTableSettingsState> {
  static const _storage = FlutterSecureStorage();
  static const _customCoursesKey = 'custom_courses';
  static const _historyClassTablesKey = 'history_class_tables';
  final Ref _ref;
  final _notificationService = NotificationService();

  ClassTableSettingsNotifier(this._ref)
    : super(
        ClassTableSettingsState(
          currentXnm: DateTime.now().year.toString(),
          currentXqm: DateTime.now().month < 7 ? '12' : '3',
        ),
      ) {
    _loadData();
    // 延迟初始化历史课表，确保成绩数据有机会加载
    _scheduleHistoryInitialization();
    // 监听成绩数据变化
    _listenToGradeChanges();
  }

  /// 加载数据
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([_loadCustomCourses(), _loadHistoryClassTables()]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载数据失败: $e');
      AppLogger.debug('❌ 加载课程表设置数据失败: $e');
    }
  }

  /// 调度历史课表初始化
  void _scheduleHistoryInitialization() {
    // 延迟3秒执行，给成绩数据加载留出时间
    Timer(const Duration(seconds: 3), () {
      _checkAndInitializeHistory();
    });
  }

  /// 检查并初始化历史课表
  Future<void> _checkAndInitializeHistory() async {
    try {
      // 如果历史课表数量少于2个，尝试从成绩数据初始化
      if (state.historyClassTables.length < 2) {
        AppLogger.debug(
          '📅 延迟检查：历史课表数量为 ${state.historyClassTables.length}，尝试从成绩数据初始化',
        );

        final gradeState = _ref.read(gradeProvider);
        if (gradeState.gradeDetails.isNotEmpty) {
          AppLogger.debug(
            '📅 发现成绩数据 ${gradeState.gradeDetails.length} 条，开始提取历史课表',
          );

          final gradeBasedTables = await _extractHistoryFromGradeDetails(
            gradeState.gradeDetails,
          );
          if (gradeBasedTables.isNotEmpty) {
            // 合并现有和新提取的历史课表
            final existingMap = <String, HistoryClassTable>{};
            for (final table in state.historyClassTables) {
              existingMap['${table.xnm}-${table.xqm}'] = table;
            }
            for (final table in gradeBasedTables) {
              existingMap['${table.xnm}-${table.xqm}'] = table;
            }

            final mergedTables = existingMap.values.toList();

            // 确保当前学期在列表中
            final finalTables = await _ensureCurrentSemesterInHistory(
              mergedTables,
            );

            // 排序
            finalTables.sort((a, b) {
              final aYear = int.tryParse(a.xnm) ?? 0;
              final bYear = int.tryParse(b.xnm) ?? 0;
              if (aYear == bYear) {
                return a.xqm.compareTo(b.xqm);
              }
              return bYear.compareTo(aYear);
            });

            // 更新状态并保存
            state = state.copyWith(historyClassTables: finalTables);
            await _saveHistoryClassTablesData(finalTables);
            AppLogger.debug('📅 延迟初始化完成，现有 ${finalTables.length} 个历史课表');
          }
        } else {
          AppLogger.debug('📅 延迟检查时仍无成绩数据，稍后再试');
          // 如果还是没有成绩数据，再延迟5秒重试一次
          Timer(const Duration(seconds: 5), () {
            _checkAndInitializeHistory();
          });
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 延迟初始化历史课表失败: $e');
    }
  }

  /// 监听成绩数据变化
  void _listenToGradeChanges() {
    // 监听成绩数据变化，当成绩数据加载完成时自动初始化历史课表
    _ref.listen<GradeState>(gradeProvider, (previous, next) {
      // 如果从没有成绩数据变为有成绩数据，且历史课表数量少于2个
      if ((previous?.gradeDetails.isEmpty ?? true) &&
          next.gradeDetails.isNotEmpty &&
          state.historyClassTables.length < 2) {
        AppLogger.debug('📅 检测到成绩数据加载完成，开始自动初始化历史课表');
        Future.microtask(() => _autoInitializeFromGrades(next.gradeDetails));
      }
    });
  }

  /// 从成绩数据自动初始化历史课表
  Future<void> _autoInitializeFromGrades(List<GradeDetail> gradeDetails) async {
    try {
      AppLogger.debug('📅 自动初始化：从 ${gradeDetails.length} 条成绩数据提取历史课表');

      final gradeBasedTables = await _extractHistoryFromGradeDetails(
        gradeDetails,
      );
      if (gradeBasedTables.isNotEmpty) {
        // 合并现有和新提取的历史课表
        final existingMap = <String, HistoryClassTable>{};
        for (final table in state.historyClassTables) {
          existingMap['${table.xnm}-${table.xqm}'] = table;
        }
        for (final table in gradeBasedTables) {
          existingMap['${table.xnm}-${table.xqm}'] = table;
        }

        final mergedTables = existingMap.values.toList();

        // 确保当前学期在列表中
        final finalTables = await _ensureCurrentSemesterInHistory(mergedTables);

        // 排序
        finalTables.sort((a, b) {
          final aYear = int.tryParse(a.xnm) ?? 0;
          final bYear = int.tryParse(b.xnm) ?? 0;
          if (aYear == bYear) {
            return a.xqm.compareTo(b.xqm);
          }
          return bYear.compareTo(aYear);
        });

        // 更新状态并保存
        state = state.copyWith(historyClassTables: finalTables);
        await _saveHistoryClassTablesData(finalTables);
        AppLogger.debug('📅 自动初始化完成，现有 ${finalTables.length} 个历史课表');

        // 输出历史课表列表
        for (final table in finalTables) {
          AppLogger.debug(
            '   - ${table.displayName} (${table.xnm}-${table.xqm})',
          );
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 自动初始化历史课表失败: $e');
    }
  }

  /// 加载自定义课程
  Future<void> _loadCustomCourses() async {
    try {
      final data = await _storage.read(key: _customCoursesKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        final courses = jsonList
            .map((json) => CustomCourse.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(customCourses: courses);
        AppLogger.debug('📚 加载了 ${courses.length} 门自定义课程');
      }
    } catch (e) {
      AppLogger.debug('❌ 加载自定义课程失败: $e');
    }
  }

  /// 加载历史课表
  Future<void> _loadHistoryClassTables() async {
    try {
      final data = await _storage.read(key: _historyClassTablesKey);
      List<HistoryClassTable> historyTables = [];

      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        historyTables = jsonList
            .map(
              (json) =>
                  HistoryClassTable.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        AppLogger.debug('📅 从存储中加载了 ${historyTables.length} 个历史课表');
        for (final table in historyTables) {
          AppLogger.debug(
            '   - ${table.displayName} (${table.xnm}-${table.xqm})',
          );
        }
      } else {
        AppLogger.debug('📅 存储中没有历史课表数据');
      }

      // 如果历史课表为空，或者只有1个（可能只有当前学期），尝试从成绩数据中初始化
      if (historyTables.isEmpty || historyTables.length == 1) {
        AppLogger.debug('📅 历史课表数量较少（${historyTables.length}个），尝试从成绩数据重新初始化');
        final gradeBasedTables = await _initHistoryFromGrades();
        if (gradeBasedTables.isNotEmpty) {
          AppLogger.debug('📅 从成绩数据中获取了 ${gradeBasedTables.length} 个学期');

          // 合并现有和新提取的历史课表
          final existingMap = <String, HistoryClassTable>{};
          for (final table in historyTables) {
            existingMap['${table.xnm}-${table.xqm}'] = table;
          }
          for (final table in gradeBasedTables) {
            existingMap['${table.xnm}-${table.xqm}'] = table;
          }

          historyTables = existingMap.values.toList();
          AppLogger.debug('📅 合并后共有 ${historyTables.length} 个历史课表');
          // 保存合并后的历史课表
          await _saveHistoryClassTablesData(historyTables);
        }
      }

      // 确保当前学期总是在历史记录中
      final originalCount = historyTables.length;
      historyTables = await _ensureCurrentSemesterInHistory(historyTables);

      // 按年份和学期排序（最新的在前）
      historyTables.sort((a, b) {
        final aYear = int.tryParse(a.xnm) ?? 0;
        final bYear = int.tryParse(b.xnm) ?? 0;
        if (aYear == bYear) {
          // 同年按学期排序：秋季(3) > 春季(12)
          return a.xqm.compareTo(b.xqm);
        }
        return bYear.compareTo(aYear);
      });

      // 如果添加了新的学期，保存到存储
      if (historyTables.length > originalCount) {
        await _saveHistoryClassTablesData(historyTables);
      }

      state = state.copyWith(historyClassTables: historyTables);
      AppLogger.debug('📅 加载了 ${historyTables.length} 个历史课表');
    } catch (e) {
      AppLogger.debug('❌ 加载历史课表失败: $e');
    }
  }

  /// 从成绩数据中初始化历史课表
  Future<List<HistoryClassTable>> _initHistoryFromGrades() async {
    try {
      final gradeState = _ref.read(gradeProvider);
      AppLogger.debug('📅 当前成绩数据条数: ${gradeState.gradeDetails.length}');
      if (gradeState.gradeDetails.isEmpty) {
        AppLogger.debug('📅 没有成绩数据，无法初始化历史课表');
        return [];
      }

      return await _extractHistoryFromGradeDetails(gradeState.gradeDetails);
    } catch (e) {
      AppLogger.debug('❌ 从成绩数据初始化历史课表失败: $e');
      return [];
    }
  }

  /// 从成绩详情中提取历史课表
  Future<List<HistoryClassTable>> _extractHistoryFromGradeDetails(
    List<GradeDetail> gradeDetails,
  ) async {
    try {
      // 从成绩数据中提取所有的学期信息
      final Set<String> semesterKeys = {};
      for (final grade in gradeDetails) {
        if (grade.xnm.isNotEmpty && grade.xqm.isNotEmpty) {
          semesterKeys.add('${grade.xnm}-${grade.xqm}');
        }
      }
      AppLogger.debug('📅 从成绩数据中提取到的学期: ${semesterKeys.toList()}');

      // 转换为HistoryClassTable对象
      final List<HistoryClassTable> historyTables = [];
      for (final semesterKey in semesterKeys) {
        final parts = semesterKey.split('-');
        if (parts.length == 2) {
          final xnm = parts[0];
          final xqm = parts[1];
          final displayName = _formatSemesterDisplayName(xnm, xqm);

          historyTables.add(
            HistoryClassTable(xnm: xnm, xqm: xqm, displayName: displayName),
          );
        }
      }

      // 按学期排序（最新的在前）
      historyTables.sort((a, b) {
        final aYear = int.tryParse(a.xnm) ?? 0;
        final bYear = int.tryParse(b.xnm) ?? 0;
        if (aYear == bYear) {
          // 同年按学期排序：秋季(3) > 春季(12)
          return a.xqm.compareTo(b.xqm);
        }
        return bYear.compareTo(aYear);
      });

      AppLogger.debug('📅 从成绩数据中提取了 ${historyTables.length} 个学期');
      return historyTables;
    } catch (e) {
      AppLogger.debug('❌ 从成绩数据初始化历史课表失败: $e');
      return [];
    }
  }

  /// 确保当前学期在历史记录中
  Future<List<HistoryClassTable>> _ensureCurrentSemesterInHistory(
    List<HistoryClassTable> existingTables,
  ) async {
    try {
      // 获取当前学期信息 - 使用state中的当前学期
      final currentXnm = state.currentXnm;
      final currentXqm = state.currentXqm;

      // 检查当前学期是否已存在
      final currentExists = existingTables.any(
        (table) => table.xnm == currentXnm && table.xqm == currentXqm,
      );

      if (!currentExists) {
        final currentSemester = HistoryClassTable(
          xnm: currentXnm,
          xqm: currentXqm,
          displayName: _formatSemesterDisplayName(currentXnm, currentXqm),
        );

        final updatedTables = [currentSemester, ...existingTables];
        AppLogger.debug('📅 添加当前学期到历史记录: ${currentSemester.displayName}');

        // 不在这里保存，让调用方决定何时保存
        return updatedTables;
      }

      return existingTables;
    } catch (e) {
      AppLogger.debug('❌ 确保当前学期在历史记录中失败: $e');
      return existingTables;
    }
  }

  /// 保存历史课表数据（内部方法）
  Future<void> _saveHistoryClassTablesData(
    List<HistoryClassTable> historyTables,
  ) async {
    try {
      final jsonList = historyTables.map((table) => table.toJson()).toList();
      await _storage.write(
        key: _historyClassTablesKey,
        value: json.encode(jsonList),
      );
      AppLogger.debug('💾 保存了 ${historyTables.length} 个历史课表');
    } catch (e) {
      AppLogger.debug('❌ 保存历史课表数据失败: $e');
    }
  }

  /// 保存自定义课程
  Future<void> _saveCustomCourses() async {
    try {
      final jsonList = state.customCourses
          .map((course) => course.toJson())
          .toList();
      await _storage.write(
        key: _customCoursesKey,
        value: json.encode(jsonList),
      );
      AppLogger.debug('💾 保存了 ${state.customCourses.length} 门自定义课程');
    } catch (e) {
      AppLogger.debug('❌ 保存自定义课程失败: $e');
      throw Exception('保存自定义课程失败');
    }
  }

  /// 保存历史课表
  Future<void> _saveHistoryClassTables() async {
    try {
      final jsonList = state.historyClassTables
          .map((table) => table.toJson())
          .toList();
      await _storage.write(
        key: _historyClassTablesKey,
        value: json.encode(jsonList),
      );
      AppLogger.debug('💾 保存了 ${state.historyClassTables.length} 个历史课表');
    } catch (e) {
      AppLogger.debug('❌ 保存历史课表失败: $e');
      throw Exception('保存历史课表失败');
    }
  }

  /// 添加自定义课程
  Future<void> addCustomCourse(CustomCourse course) async {
    try {
      final updatedCourses = [...state.customCourses, course];
      state = state.copyWith(customCourses: updatedCourses);
      await _saveCustomCourses();
      AppLogger.debug('✅ 添加自定义课程: ${course.title}');

      // 🔔 只有当前学期的自定义课程才调度通知
      if (_isCurrentSemester(course.xnm, course.xqm)) {
        await rescheduleNotificationsAfterRefresh();
      } else {
        AppLogger.debug('🔔 添加的是历史学期课程，不调度通知');
      }
    } catch (e) {
      state = state.copyWith(error: '添加课程失败: $e');
      AppLogger.debug('❌ 添加自定义课程失败: $e');
      rethrow;
    }
  }

  /// 更新自定义课程
  Future<void> updateCustomCourse(CustomCourse updatedCourse) async {
    try {
      final updatedCourses = state.customCourses.map((course) {
        return course.id == updatedCourse.id ? updatedCourse : course;
      }).toList();

      state = state.copyWith(customCourses: updatedCourses);
      await _saveCustomCourses();
      AppLogger.debug('✅ 更新自定义课程: ${updatedCourse.title}');

      // 🔔 只有当前学期的自定义课程才调度通知
      if (_isCurrentSemester(updatedCourse.xnm, updatedCourse.xqm)) {
        await rescheduleNotificationsAfterRefresh();
      } else {
        AppLogger.debug('🔔 更新的是历史学期课程，不调度通知');
      }
    } catch (e) {
      state = state.copyWith(error: '更新课程失败: $e');
      AppLogger.debug('❌ 更新自定义课程失败: $e');
      rethrow;
    }
  }

  /// 删除自定义课程
  Future<void> deleteCustomCourse(String courseId) async {
    try {
      // 找到要删除的课程，判断是否是当前学期
      final courseToDelete = state.customCourses.firstWhere(
        (course) => course.id == courseId,
      );
      final isCurrentSem = _isCurrentSemester(
        courseToDelete.xnm,
        courseToDelete.xqm,
      );

      final updatedCourses = state.customCourses
          .where((course) => course.id != courseId)
          .toList();

      state = state.copyWith(customCourses: updatedCourses);
      await _saveCustomCourses();
      AppLogger.debug('✅ 删除自定义课程: $courseId');

      // 🔔 只有当前学期的自定义课程才调度通知
      if (isCurrentSem) {
        await rescheduleNotificationsAfterRefresh();
      } else {
        AppLogger.debug('🔔 删除的是历史学期课程，不调度通知');
      }
    } catch (e) {
      state = state.copyWith(error: '删除课程失败: $e');
      AppLogger.debug('❌ 删除自定义课程失败: $e');
      rethrow;
    }
  }

  /// 添加历史课表
  Future<void> addHistoryClassTable(String xnm, String xqm) async {
    try {
      final displayName = _formatSemesterDisplayName(xnm, xqm);
      final newHistoryTable = HistoryClassTable(
        xnm: xnm,
        xqm: xqm,
        displayName: displayName,
      );

      // 检查是否已存在
      final existingIndex = state.historyClassTables.indexWhere(
        (table) => table.xnm == xnm && table.xqm == xqm,
      );

      List<HistoryClassTable> updatedTables;
      if (existingIndex == -1) {
        // 添加新记录（如果不存在）
        updatedTables = [newHistoryTable, ...state.historyClassTables];

        // 限制历史记录数量
        if (updatedTables.length > 10) {
          updatedTables = updatedTables.take(10).toList();
        }
      } else {
        // 已存在，不需要重复添加
        updatedTables = state.historyClassTables;
      }

      // 按年份和学期排序（最新的在前）
      updatedTables.sort((a, b) {
        final aYear = int.tryParse(a.xnm) ?? 0;
        final bYear = int.tryParse(b.xnm) ?? 0;
        if (aYear == bYear) {
          // 同年按学期排序：秋季(3) > 春季(12)
          return a.xqm.compareTo(b.xqm);
        }
        return bYear.compareTo(aYear);
      });

      state = state.copyWith(historyClassTables: updatedTables);
      await _saveHistoryClassTables();
      AppLogger.debug('✅ 添加历史课表: $displayName');
    } catch (e) {
      AppLogger.debug('❌ 添加历史课表失败: $e');
    }
  }

  /// 格式化学期显示名称
  String _formatSemesterDisplayName(String xnm, String xqm) {
    final year = int.tryParse(xnm) ?? DateTime.now().year;
    if (xqm == '12') {
      return '${year + 1}年春季学期';
    } else if (xqm == '3') {
      return '$year年秋季学期';
    } else {
      return '$year年夏季学期';
    }
  }

  /// 清除错误状态
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadData();
  }

  /// 手动刷新历史课表（当成绩数据更新后调用）
  Future<void> refreshHistoryFromGrades() async {
    try {
      AppLogger.debug('🔄 开始刷新历史课表...');

      // 首先刷新成绩数据
      try {
        await _ref.read(gradeProvider.notifier).refreshGrades();
      } catch (e) {
        AppLogger.debug('❌ 刷新成绩数据失败: $e');
      }

      // 从成绩数据获取历史课表
      final historyTables = await _initHistoryFromGrades();

      if (historyTables.isNotEmpty) {
        // 确保当前学期在列表中
        final finalTables = await _ensureCurrentSemesterInHistory(
          historyTables,
        );

        // 排序
        finalTables.sort((a, b) {
          final aYear = int.tryParse(a.xnm) ?? 0;
          final bYear = int.tryParse(b.xnm) ?? 0;
          if (aYear == bYear) {
            // 同年按学期排序：秋季(3) > 春季(12)
            return a.xqm.compareTo(b.xqm);
          }
          return bYear.compareTo(aYear);
        });

        // 更新状态并保存
        state = state.copyWith(historyClassTables: finalTables);
        await _saveHistoryClassTablesData(finalTables);
        AppLogger.debug('🔄 已刷新历史课表，现有 ${finalTables.length} 个历史课表');
      } else {
        AppLogger.debug('📅 从成绩数据中未获取到历史课表，可能没有成绩数据');

        // 如果没有历史课表，至少确保当前学期存在
        final currentTables = await _ensureCurrentSemesterInHistory([]);
        if (currentTables.isNotEmpty) {
          state = state.copyWith(historyClassTables: currentTables);
          await _saveHistoryClassTablesData(currentTables);
          AppLogger.debug('📅 添加了当前学期到历史课表');
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 刷新历史课表失败: $e');
    }
  }

  /// 手动添加当前学期到历史记录
  Future<void> addCurrentSemesterToHistory() async {
    try {
      final originalCount = state.historyClassTables.length;
      final updatedTables = await _ensureCurrentSemesterInHistory(
        state.historyClassTables,
      );

      updatedTables.sort((a, b) {
        final aYear = int.tryParse(a.xnm) ?? 0;
        final bYear = int.tryParse(b.xnm) ?? 0;
        if (aYear == bYear) {
          // 同年按学期排序：秋季(3) > 春季(12)
          return a.xqm.compareTo(b.xqm);
        }
        return bYear.compareTo(aYear);
      });

      // 如果添加了新的学期，保存到存储
      if (updatedTables.length > originalCount) {
        await _saveHistoryClassTablesData(updatedTables);
      }

      state = state.copyWith(historyClassTables: updatedTables);
      AppLogger.debug('✅ 手动添加当前学期到历史记录完成');
    } catch (e) {
      AppLogger.debug('❌ 手动添加当前学期失败: $e');
    }
  }

  /// 切换到指定学期
  Future<void> switchSemester(String xnm, String xqm) async {
    try {
      AppLogger.debug('🔄 开始切换学期: $xnm-$xqm');

      // 更新当前学期状态
      state = state.copyWith(currentXnm: xnm, currentXqm: xqm);

      // 根据微信小程序的逻辑，动态设置学期开始日期
      // 春季学期（xqm="12"）：使用2月15日
      // 秋季学期（xqm="3"）：使用8月15日
      final startMonth = xqm == '12' ? '02' : '08';
      final semesterStartDate = '$xnm-$startMonth-15';

      AppLogger.debug('📅 设置学期开始日期: $semesterStartDate');

      // 获取并保存课表数据
      await _ref.read(classTableRepositoryProvider).fetchRemote(xnm, xqm);

      // 刷新课表提供器以更新UI
      _ref.invalidate(classTableProvider((xnm: xnm, xqm: xqm)));

      AppLogger.debug('✅ 学期切换成功: $xnm-$xqm');

      // ⚠️ 注意：切换学期只是查看历史课表，不修改通知
      // 通知始终针对当前实际学期，不受查看的学期影响
    } catch (e) {
      AppLogger.debug('❌ 切换学期失败: $e');
      rethrow;
    }
  }

  // ==================== 辅助方法 ====================

  /// 判断是否是当前实际学期
  bool _isCurrentSemester(String xnm, String xqm) {
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final currentXqm = now.month < 7 ? '12' : '3';

    return xnm == currentYear && xqm == currentXqm;
  }

  // ==================== 通知相关方法 ====================

  /// 手动触发通知重新调度（用于课表刷新后）
  /// 这个方法应该在 UI 层调用，在刷新课表后
  Future<void> rescheduleNotificationsAfterRefresh() async {
    try {
      // 获取当前学期的完整课表（包含自定义课程）
      final classTable = await _ref.read(
        classTableProvider((
          xnm: state.currentXnm,
          xqm: state.currentXqm,
        )).future,
      );

      // 调用 NotificationService 的重新调度方法
      await _notificationService.rescheduleCourseNotificationsForSemester(
        classTable: classTable,
        xnm: state.currentXnm,
        xqm: state.currentXqm,
      );
    } catch (e) {
      AppLogger.error('🔔 重新调度课程通知失败: $e');
    }
  }
}

/// 课程表设置 Provider
final classTableSettingsProvider =
    StateNotifierProvider<ClassTableSettingsNotifier, ClassTableSettingsState>(
      (ref) => ClassTableSettingsNotifier(ref),
    );

/// 当前学期的自定义课程 Provider
final currentSemesterCustomCoursesProvider = Provider<List<CustomCourse>>((
  ref,
) {
  final settings = ref.watch(classTableSettingsProvider);
  // 这里可以根据需要过滤特定学期的课程
  return settings.customCourses;
});
