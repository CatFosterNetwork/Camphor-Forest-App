// lib/core/constants/route_constants.dart

abstract class RouteConstants {
  // 登录
  static const String login = '/login';
  static const String userAgreement = '/userAgreement';

  // 选项页 & 子路由
  static const String options = '/options';
  static const String optionsIndexSettings = '/options/indexSettings';
  static const String optionsThemeSettings = '/options/themeSettings';
  static const String optionsProfileSettings = '/options/profileSettings';
  static const String optionsOtherSettings = '/options/otherSettings';
  static const String optionsCustomThemeSettings =
      '/options/customThemeSettings';
  static const String optionsAbout = '/options/about';

  // 绑定宿舍（水电费）
  static const String expense = '/expense';

  // TabBar 首页
  static const String index = '/index';

  // 校招讯息
  static const String campusRecruitment = '/campusRecruitment';

  // BBS
  static const String bbs = '/bbs';

  // 课程表
  static const String classTable = '/classTable';
  static const String classTableCustomize = '/classTable/customize';

  // 个人中心
  static const String home = '/home';
  static const String modifyPersonalInfo = '/home/modifyPersonalInfo';

  // 反馈
  static const String feedback = '/feedback';
  static const String feedbackAdd = '/feedback/add';
  static const String feedbackDetail = '/feedback/detail';

  // 文章发表/详情（通过 queryParam articleId）
  static const String articlePublish = '/bbs/articlePublish';
  static const String articleDetail = '/bbs/articleDetail';

  // 校园生活
  static const String lifeService = '/lifeService';
  static const String exams = '/lifeService/exams';
  static const String classroom = '/lifeService/classroom';
  static const String grade = '/lifeService/grade';
  static const String calendar = '/lifeService/calendar';
  static const String expenseQuery = '/lifeService/expense';
  static const String dormBind = '/lifeService/dormBind';

  // 统计数字
  static const String statistics = '/statistics';
  // 校园导航
  static const String schoolNavigation = '/schoolNavigation';

  // 图书馆
  static const String library = '/library';

  // 跳蚤市场
  static const String fleaMarket = '/fleaMarket';
}
