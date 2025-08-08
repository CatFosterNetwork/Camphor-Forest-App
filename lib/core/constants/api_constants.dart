// lib/core/constants/api_constants.dart

class ApiConstants {
  /// Base URL for most endpoints
  static const String baseUrl = 'https://forest.swu.social';

  /// IP 信息接口（绝对地址，绕过 baseUrl）
  static const String ipInfoUrl = 'https://www.ipip.net/ip-js/';

  /// Passage 模块 base（原 SiteConfig.passageUrl）
  static const String passageUrl = '$baseUrl/passage';

  // 普通接口
  static const String weather = '/api/weather';
  static const String frontPage = '/api/frontPage';
  static const String swuLogin = '/api/swuLogin';
  static const String home = '/api/home';
  static const String menu = '/api/menu';
  static const String classTable = '/api/classTable';
  static const String electricityExpense = '/api/electricityExpense';
  static const String grades = '/api/grades';
  static const String todo = '/api/todo/';
  static const String examInfo = '/api/examInfoEnquiry';
  static const String classroom = '/api/classRoomEnquiry';
  static const String feedback = '/api/feedback';
  static const String settings = '/api/user/settings';
  static const String studyCertificate = '/api/dzpz/studyCertificate';
  static const String sendStudyCertificate = '/api/dzpz/studyCertificate/send';
  static const String campusRecruitment = '/campusRecruitment';
  static const String upload = '/api/upload';
  static const String statistics = '/api/statistics/course';
  static const String updateOpenId = '/api/updateOpenId';
  static const String features = '/api/properties/features';

  /// JWT 过期检测
  static const String jwtIsExpired = '/api/jwt/isExpired';

  /// 请求微信授权码
  static const String weixinCode = '/api/weixin/code';

  // 外部地址
  static const String ossUrl = 'https://upload.swu.social';
  static const String dataUrl = 'https://data.swu.social/';

  // Passage 相关（动态 ID 或分页）
  static String articleById(int id) => '$passageUrl/$id';
  static const String articleList = '$passageUrl/articleList';
  static String articlesByCategory(int cat) => '$passageUrl/category/$cat';
  static const String searchArticle = '$passageUrl/search';
  static const String publishArticle = passageUrl;
  static String likeArticle(int id) => '$passageUrl/$id/like';
  static String likeArticleStatus(int id) => '$passageUrl/$id/like';
  static String reply(int id) => '$passageUrl/$id/reply';
  static String getReplies(int id) => '$passageUrl/$id/reply';

  // todo 动态 ID
  static String todoById(int id) => '$todo/$id';

  // 统一超时配置
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;

  // 全局默认请求头
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
