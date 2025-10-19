// lib/core/navigation/app_router.dart

import 'dart:async';

import '../../core/utils/app_logger.dart';

import 'package:camphor_forest/core/providers/core_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_constants.dart';
import '../services/navigation_service.dart';

// —— Authentication
import '../../pages/login/login_screen.dart';
import '../../pages/login/user_agreement.dart';
// —— Options
import '../../pages/settings/options_screen.dart';
import '../../pages/settings/index_settings_page.dart';
import '../../pages/settings/theme_settings_page.dart';
import '../../pages/settings/profile_settings_page.dart';
import '../../pages/settings/other_settings_page.dart';
import '../../pages/settings/custom_theme_settings_page.dart';
import '../../pages/settings/about_page.dart';
// // —— Expense
// import '../../pages/expense/pages/expense_screen.dart';
// // —— Index (TabBar)
import '../../pages/index/index_screen.dart';
// // —— CampusRecruitment
// import '../../pages/campus_recruitment/pages/campus_recruitment_screen.dart';
// —— BBS
import '../../pages/bbs/bbs_screen.dart';
// import '../../pages/bbs/pages/article_publish_screen.dart';
// import '../../pages/bbs/pages/article_detail_screen.dart';
// // —— ClassTable
import '../../pages/classtable/classtable_screen.dart';
import '../../pages/classtable/custom_classtable_screen.dart';
// // —— Home / Profile
// import '../../pages/home/pages/home_screen.dart';
// import '../../pages/home/pages/modify_personal_info_screen.dart';
// —— Feedback
import '../../pages/feedback/feedback_screen.dart';
import '../../pages/feedback/add_feedback_screen.dart';
import '../../pages/feedback/feedback_detail_screen.dart';
// —— LifeService
import '../../pages/lifeService/life_service_screen.dart';
import '../../pages/lifeService/pages/exam_query_screen.dart';
import '../../pages/lifeService/pages/classroom_query_screen.dart';
import '../../pages/lifeService/pages/grade_query_screen.dart';
import '../../pages/lifeService/pages/calendar_view_screen.dart';
import '../../pages/lifeService/pages/expense_query_screen.dart';
import '../../pages/lifeService/pages/dorm_bind_screen.dart';
// —— Statistics
import '../../pages/statistics/statistics_screen.dart';
// —— School Navigation
import '../../pages/school_navigation/school_navigation_screen.dart';

/// 监听 [stream]，每当有事件发出就调用 notifyListeners()，
/// 供 GoRouter 的 refreshListenable 使用。
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// 全局路由器
final goRouterProvider = Provider<GoRouter>((ref) {
  // 注意：authProvider 现在抛出未实现错误，我们需要使用异步版本
  // final authNotifier = ref.read(authProvider.notifier);
  // final initialized = ref.watch(authProvider.select((s) => s.initialized));

  // 直接获取UserService的Future，在redirect中处理异步
  final userServiceFuture = ref.read(userServiceProvider.future);

  final whitelist = <String>{RouteConstants.userAgreement};
  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,

    initialLocation: RouteConstants.login,
    debugLogDiagnostics: true,

    // 注意：refreshListenable 暂时移除，因为 authProvider 需要重构
    // 登录状态检查通过 redirect 函数处理
    routes: <RouteBase>[
      GoRoute(
        path: RouteConstants.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.userAgreement,
        builder: (ctx, state) => const UserAgreementPage(),
      ),
      GoRoute(
        path: RouteConstants.options,
        builder: (ctx, state) => const OptionsScreen(),
      ),
      GoRoute(
        path: RouteConstants.optionsIndexSettings,
        builder: (ctx, state) => const IndexSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.optionsThemeSettings,
        builder: (ctx, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.optionsProfileSettings,
        builder: (ctx, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.optionsOtherSettings,
        builder: (ctx, state) => const OtherSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.optionsCustomThemeSettings,
        builder: (ctx, state) {
          final themeId = state.extra as String?;
          return CustomThemeSettingsPage(themeId: themeId);
        },
      ),
      GoRoute(
        path: RouteConstants.optionsAbout,
        builder: (ctx, state) => const AboutPage(),
      ),
      // GoRoute(
      //   path: RouteConstants.expense,
      //   builder: (ctx, state) => const ExpenseScreen(),
      // ),
      GoRoute(
        path: RouteConstants.index,
        builder: (ctx, state) => const IndexScreen(),
      ),
      // GoRoute(
      //   path: RouteConstants.campusRecruitment,
      //   builder: (ctx, state) => const CampusRecruitmentScreen(),
      // ),
      GoRoute(
        path: RouteConstants.bbs,
        builder: (ctx, state) => const BBSScreen(),
      ),
      // GoRoute(
      //   path: RouteConstants.bbs,
      //   builder: (ctx, state) => const BbsScreen(),
      //   routes: [
      //     GoRoute(
      //       path: 'articlePublish',
      //       name: RouteConstants.articlePublish,
      //       builder: (ctx, state) {
      //         final articleId = state.queryParams['articleId'];
      //         return ArticlePublishScreen(articleId: articleId);
      //       },
      //     ),
      //     GoRoute(
      //       path: 'articleDetail',
      //       name: RouteConstants.articleDetail,
      //       builder: (ctx, state) {
      //         final articleId = state.queryParams['articleId'];
      //         return ArticleDetailScreen(articleId: articleId);
      //       },
      //     ),
      //   ],
      // ),
      GoRoute(
        path: RouteConstants.classTable,
        builder: (ctx, state) => const ClassTableScreen(),
      ),
      GoRoute(
        path: RouteConstants.classTableCustomize,
        builder: (ctx, state) => const CustomClassTableScreen(),
      ),
      // GoRoute(
      //   path: RouteConstants.home,
      //   builder: (ctx, state) => const HomeScreen(),
      //   routes: [
      //     GoRoute(
      //       path: 'modifyPersonalInfo',
      //       name: RouteConstants.modifyPersonalInfo,
      //       builder: (ctx, state) => const ModifyPersonalInfoScreen(),
      //     ),
      //   ],
      // ),
      GoRoute(
        path: RouteConstants.feedback,
        builder: (ctx, state) => const FeedbackScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: RouteConstants.feedbackAdd,
            builder: (ctx, state) => const AddFeedbackScreen(),
          ),
          GoRoute(
            path: 'detail',
            name: RouteConstants.feedbackDetail,
            builder: (ctx, state) {
              final id = state.queryParameters['id'] ?? '';
              return FeedbackDetailScreen(feedbackId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.lifeService,
        builder: (ctx, state) => const LifeServiceScreen(),
        routes: [
          GoRoute(
            path: 'exams',
            name: RouteConstants.exams,
            builder: (ctx, state) => const ExamQueryScreen(),
          ),
          GoRoute(
            path: 'classroom',
            name: RouteConstants.classroom,
            builder: (ctx, state) => const ClassroomQueryScreen(),
          ),
          GoRoute(
            path: 'grade',
            name: RouteConstants.grade,
            builder: (ctx, state) => const GradeQueryScreen(),
          ),
          GoRoute(
            path: 'calendar',
            name: RouteConstants.calendar,
            builder: (ctx, state) => const CalendarViewScreen(),
          ),
          GoRoute(
            path: 'expense',
            name: RouteConstants.expenseQuery,
            builder: (ctx, state) => const ExpenseQueryScreen(),
          ),
          GoRoute(
            path: 'dormBind',
            name: RouteConstants.dormBind,
            builder: (ctx, state) => const DormBindScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.statistics,
        builder: (ctx, state) {
          final kch = state.queryParameters['kch'];
          final courseName = state.queryParameters['courseName'];
          return StatisticsScreen(kch: kch, courseName: courseName);
        },
      ),
      GoRoute(
        path: RouteConstants.schoolNavigation,
        builder: (ctx, state) => const SchoolNavigationScreen(),
      ),
    ],

    // 全局重定向（登录守卫）
    redirect: (context, state) async {
      if (whitelist.contains(state.location)) {
        return null;
      }

      try {
        // 等待UserService加载完成
        final userService = await userServiceFuture;

        // 检查登录状态
        final isLoggedIn = await userService.check();

        if (!isLoggedIn && state.location != RouteConstants.login) {
          return RouteConstants.login; // 未登录且不是访问登录页面，则跳转到登录
        } else if (isLoggedIn && state.location == RouteConstants.login) {
          return RouteConstants.index;
        } else {
          return null;
        }
      } catch (e) {
        // 如果UserService加载失败，重定向到登录页面
        AppLogger.debug('AppRouter: UserService加载失败: $e');
        if (state.location != RouteConstants.login) {
          return RouteConstants.login;
        }
        return null;
      }
    },
  );
});
