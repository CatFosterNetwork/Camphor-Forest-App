// lib/pages/statistics/providers/statistics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/grade_provider.dart' as grade_provider;
import '../../classtable/providers/classtable_providers.dart';
import '../models/statistics_model.dart';

// 单个课程统计提供者

// 课程统计参数类
class CourseStatisticsParams {
  final String courseId;
  final String? courseName;

  CourseStatisticsParams({required this.courseId, this.courseName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseStatisticsParams &&
          runtimeType == other.runtimeType &&
          courseId == other.courseId &&
          courseName == other.courseName;

  @override
  int get hashCode => courseId.hashCode ^ courseName.hashCode;
}

// 新增：单个课程统计提供者
final courseStatisticsProvider =
    FutureProvider.family<CourseStatisticsData?, CourseStatisticsParams>((
      ref,
      params,
    ) async {
      final apiService = ref.read(apiServiceProvider);

      try {
        // 从API获取单个课程的统计数据
        final response = await apiService.getCourseStatistics(params.courseId);

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          return CourseStatisticsData.fromApi(
            courseId: params.courseId,
            courseName: params.courseName ?? '未知课程',
            apiData: data,
          );
        }

        return null;
      } catch (e) {
        print('Error getting course statistics for ${params.courseId}: $e');
        return null;
      }
    });

// 学期相关的Provider
// 学期信息类
class SemesterInfo {
  final String xnm; // 学年
  final String xqm; // 学期码
  final String displayName; // 显示名称

  SemesterInfo({
    required this.xnm,
    required this.xqm,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterInfo &&
          runtimeType == other.runtimeType &&
          xnm == other.xnm &&
          xqm == other.xqm;

  @override
  int get hashCode => xnm.hashCode ^ xqm.hashCode;
}

// 参考微信小程序的逻辑：getCurrentXnmXqm
final selectedSemesterProvider = StateProvider<SemesterInfo>((ref) {
  final currentYear = DateTime.now().year;
  final currentMonth = DateTime.now().month;

  // 微信小程序逻辑：new Date().getMonth() < 7 ? "12" : "3"
  if (currentMonth < 7) {
    // 1-6月为春季学期，xqm=12，xnm=currentYear-1
    return SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '12',
      displayName: '$currentYear年春季学期',
    );
  } else {
    // 7-12月为秋季学期，xqm=3，xnm=currentYear
    return SemesterInfo(
      xnm: '$currentYear',
      xqm: '3',
      displayName: '$currentYear年秋季学期',
    );
  }
});

final availableSemestersProvider = Provider<List<SemesterInfo>>((ref) {
  final currentYear = DateTime.now().year;
  return [
    // 当前学年秋季学期
    SemesterInfo(
      xnm: '$currentYear',
      xqm: '3',
      displayName: '$currentYear年秋季学期',
    ),
    // 当前学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '12',
      displayName: '$currentYear年春季学期',
    ),
    // 上一学年秋季学期
    SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '3',
      displayName: '${currentYear - 1}年秋季学期',
    ),
    // 上一学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 2}',
      xqm: '12',
      displayName: '${currentYear - 1}年春季学期',
    ),
    // 前两学年秋季学期
    SemesterInfo(
      xnm: '${currentYear - 2}',
      xqm: '3',
      displayName: '${currentYear - 2}年秋季学期',
    ),
    // 前两学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 3}',
      xqm: '12',
      displayName: '${currentYear - 2}年春季学期',
    ),
  ];
});

// 获取指定学期的课程列表
final semesterCoursesProvider =
    FutureProvider.family<List<CourseInfo>, SemesterInfo>((
      ref,
      semesterInfo,
    ) async {
      try {
        final xnm = semesterInfo.xnm;
        final xqm = semesterInfo.xqm;

        // 1. 从本地缓存读取课表
        final classTableAsync = ref.read(
          classTableProvider((xnm: xnm, xqm: xqm)),
        );

        // 2. 从 gradeProvider 读取已缓存的成绩数据
        final gradeState = ref.read(grade_provider.gradeProvider);
        final gradesData = gradeState.gradeDetails;

        print('📚 本地成绩数据数量: ${gradesData.length}');

        // 3. 从课表和成绩中提取课程信息
        final Set<CourseInfo> courseSet = {};

        // 首先从成绩数据中提取该学期的课程
        int matchingGrades = 0;
        for (final grade in gradesData) {
          // 只提取匹配当前学期的课程
          if (grade.xnm == xnm && grade.xqm == xqm) {
            final kch = grade.kch;
            final kcmc = grade.kcmc;

            if (kch.isNotEmpty && kcmc.isNotEmpty) {
              courseSet.add(CourseInfo(id: kch, name: kcmc));
              matchingGrades++;
            }
          }
        }

        print('🎯 从成绩数据中找到 $matchingGrades 门课程');

        // 如果成绩数据中没有找到课程，再从课表数据中提取
        if (courseSet.isEmpty) {
          print('⚠️ 成绩数据中没有该学期课程，尝试从课表中提取...');

          await classTableAsync.when(
            data: (classTable) {
              // 获取所有课程
              final courses = classTable
                  .getAllCourses()
                  .values
                  .expand((e) => e)
                  .toList();

              print('📚 课表中共有 ${courses.length} 门课程');

              // 处理每门课程
              for (final course in courses) {
                String kch = course.id;
                final kcmc = course.title;

                // 如果课表中的课程ID是自定义的（以 custom_ 开头），尝试从成绩中匹配
                if (kch.startsWith('custom_') && kcmc.isNotEmpty) {
                  try {
                    final matchingGrade = gradesData.firstWhere(
                      (grade) => grade.kcmc == kcmc,
                    );
                    kch = matchingGrade.kch;
                    print('🔗 课程 $kcmc 从成绩中匹配到 kch: $kch');
                  } catch (e) {
                    // 没找到匹配的成绩，跳过
                  }
                }

                // 只添加有效的课程ID
                if (kch.isNotEmpty &&
                    !kch.startsWith('custom_') &&
                    kcmc.isNotEmpty) {
                  courseSet.add(CourseInfo(id: kch, name: kcmc));
                }
              }

              print('📋 从课表中提取了 ${courseSet.length} 门课程');
            },
            loading: () {
              print('⏳ 课表数据加载中...');
            },
            error: (error, stack) {
              print('❌ 课表数据加载失败: $error');
            },
          );
        }

        final result = courseSet.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        print('✅ 最终课程列表: ${result.length} 门课程');

        return result;
      } catch (e) {
        print('Error getting semester courses: $e');
        return [];
      }
    });

// 课程信息类
class CourseInfo {
  final String id;
  final String name;

  CourseInfo({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
