// lib/core/services/api_service.dart

import 'dart:convert';
import 'package:camphor_forest/core/network/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/i_http_client.dart';
import '../constants/api_constants.dart';
import '../models/ip_info_model.dart';

class ApiService {
  final IHttpClient _http;
  final FlutterSecureStorage _secureStorage;

  ApiService(this._http, this._secureStorage);

  /// 获得 IP 信息（绕过 baseUrl）
  Future<IpInfo> getIpInfo() async {
    final body = await _http.get<String>(
      ApiConstants.ipInfoUrl,
      headers: {'Referer': 'None'},
      responseType: ResponseType.plain,
      converter: (d) => d as String,
    );

    final ipMatch = RegExp(r"\.text\('(.+?)'\)").firstMatch(body);
    final locMatch = RegExp(r"#ip-loc'\)\.text\('(.+?)'\)").firstMatch(body);

    final ip = ipMatch?.group(1) ?? '';
    final loc = locMatch?.group(1) ?? '未知地点';
    return IpInfo(ip: ip, loc: loc);
  }

  /// 检测 JWT 是否过期
  Future<Map<String, dynamic>> getJwtIsExpired(bool autoRenew) =>
      _http.get<Map<String, dynamic>>(
        ApiConstants.jwtIsExpired,
        converter: (d) => d as Map<String, dynamic>,
        queryParameters: {'autoRenew': autoRenew},
      );

  /// 请求微信授权码
  Future<String> requestWeixinCode() =>
      _http.get<String>(ApiConstants.weixinCode, converter: (d) => d as String);

  /// 天气
  Future<Map<String, dynamic>> getWeather() => _http.get<Map<String, dynamic>>(
    ApiConstants.weather,
    converter: (d) => d as Map<String, dynamic>,
  );

  /// 首页
  Future<Map<String, dynamic>> frontPage() => _http.get<Map<String, dynamic>>(
    ApiConstants.frontPage,
    converter: (d) => d as Map<String, dynamic>,
  );

  /// 文章
  Future<Map<String, dynamic>> getArticleById(int id) =>
      _http.get<Map<String, dynamic>>(
        ApiConstants.articleById(id),
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<List<dynamic>> getArticleList(int pageNo) => _http.get<List<dynamic>>(
    ApiConstants.articleList,
    converter: (d) => d as List<dynamic>,
    queryParameters: {'pageNo': pageNo},
  );

  Future<List<dynamic>> getArticleListByCategory(int category, int pageNo) =>
      _http.get<List<dynamic>>(
        ApiConstants.articlesByCategory(category),
        converter: (d) => d as List<dynamic>,
        queryParameters: {'pageNo': pageNo},
      );

  Future<List<dynamic>> searchArticle(
    String method,
    dynamic condition,
    int pageNo,
  ) => _http.get<List<dynamic>>(
    ApiConstants.searchArticle,
    converter: (d) => d as List<dynamic>,
    queryParameters: {
      'method': method,
      'condition': condition,
      'pageNo': pageNo,
    },
  );

  Future<Map<String, dynamic>> publishArticle(Map<String, dynamic> article) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.publishArticle,
        data: article,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<void> likeArticle(int id) =>
      _http.post<void>(ApiConstants.likeArticle(id), converter: (_) {});

  Future<bool> getLikeArticleStatus(int id) => _http.get<bool>(
    ApiConstants.likeArticleStatus(id),
    converter: (d) => d as bool,
  );

  Future<Map<String, dynamic>> reply(int id, Map<String, dynamic> body) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.reply(id),
        data: body,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<List<dynamic>> getReplyList(int id, int pageNo) =>
      _http.get<List<dynamic>>(
        ApiConstants.getReplies(id),
        converter: (d) => d as List<dynamic>,
        queryParameters: {'pageNo': pageNo},
      );

  Future<List<dynamic>> getSecondaryReplyList(int id, int pageNo, int root) =>
      _http.get<List<dynamic>>(
        ApiConstants.reply(id),
        converter: (d) => d as List<dynamic>,
        queryParameters: {'pageNo': pageNo, 'rootReplyId': root},
      );

  /// 登录
  Future<Map<String, dynamic>> swuLogin(
    Map<String, dynamic> credentials,
  ) async {
    final dio = (_http as dynamic).dio as Dio;
    final resp = await dio.post(
      ApiConstants.swuLogin,
      data: credentials,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ),
    );

    // 原始数据
    final body = resp.data as Map<String, dynamic>? ?? {};
    // 把 headers 转成简单的 String→String
    final hdrs = <String, String>{};
    resp.headers.forEach((k, v) {
      hdrs[k] = v.join(';');
    });

    // 统一扁平化返回
    return {
      'data': body['data'],
      'success': body['success'] ?? false,
      '__headers': hdrs,
      'code': body['code'],
      'msg': body['msg'],
    };
  }

  /// 用户首页信息
  Future<Map<String, dynamic>> getHome() => _http.get<Map<String, dynamic>>(
    ApiConstants.home,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> modifyPersonalInfo(Map<String, dynamic> user) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.home,
        data: user,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<List<dynamic>> getMenu() => _http.get<List<dynamic>>(
    ApiConstants.menu,
    converter: (d) => d as List<dynamic>,
  );

  Future<Map<String, dynamic>> getClassTable({String? xnm, String? xqm}) =>
      _http.get<Map<String, dynamic>>(
        ApiConstants.classTable,
        converter: (d) => d as Map<String, dynamic>,
        queryParameters: (xnm != null && xqm != null)
            ? {'xnm': xnm, 'xqm': xqm}
            : null,
      );

  Future<Map<String, dynamic>> getElectricityExpense(
    String buildingId,
    String roomCode,
  ) => _http.get<Map<String, dynamic>>(
    ApiConstants.electricityExpense,
    converter: (d) => d as Map<String, dynamic>,
    queryParameters: {'buildingId': buildingId, 'roomCode': roomCode},
  );

  Future<Map<String, dynamic>> getGrades() => _http.get<Map<String, dynamic>>(
    ApiConstants.grades,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> getTodo() => _http.get<Map<String, dynamic>>(
    ApiConstants.todo,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> addTodo(Map<String, dynamic> todo) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.todo,
        data: todo,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<void> deleteTodo(int id) =>
      _http.delete<void>(ApiConstants.todoById(id), converter: (_) {});

  Future<Map<String, dynamic>> modifyTodo(int id, Map<String, dynamic> todo) =>
      _http.put<Map<String, dynamic>>(
        ApiConstants.todoById(id),
        data: todo,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<List<dynamic>> getExamInfo() => _http.get<List<dynamic>>(
    ApiConstants.examInfo,
    converter: (d) => d as List<dynamic>,
  );

  Future<Map<String, dynamic>> getClassroom({
    required String xqhId,
    required String zcd,
    required String xqj,
    required String jcd,
    required String lh,
  }) => _http.post<Map<String, dynamic>>(
    ApiConstants.classroom,
    data: {'xqh_id': xqhId, 'zcd': zcd, 'xqj': xqj, 'jcd': jcd, 'lh': lh},
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> getFeedback({
    required String query,
    required int pageNo,
    String status = '',
    int pageSize = 20,
  }) => _http.get<Map<String, dynamic>>(
    ApiConstants.feedback,
    converter: (d) => d as Map<String, dynamic>,
    queryParameters: {
      'query': query,
      'pageNo': pageNo,
      'pageSize': pageSize,
      'status': status,
      'platform': 'app',
    },
  );

  Future<Map<String, dynamic>> addFeedback({
    required String title,
    required String replyEmail,
    required String content,
    String? resourceUrl,
  }) => _http.post<Map<String, dynamic>>(
    ApiConstants.feedback,
    data: {
      'title': title,
      'replyEmail': replyEmail,
      'content': content,
      'platform': 'app',
      if (resourceUrl != null) 'resourceUrl': resourceUrl,
    },
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> getFeedbackDetail(int id) =>
      _http.get<Map<String, dynamic>>(
        '${ApiConstants.feedback}/$id',
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<dynamic> getFeedbackReplyList({
    required int id,
    required int pageNo,
    required int pageSize,
  }) => _http.get<dynamic>(
    '${ApiConstants.feedback}/$id/reply',
    converter: (d) => d,
    queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
  );

  Future<Map<String, dynamic>> addFeedbackReply({
    required int id,
    required String content,
  }) => _http.post<Map<String, dynamic>>(
    '${ApiConstants.feedback}/$id/reply',
    data: {'content': content},
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<void> setFeedbackResolved(int id) => _http.put<void>(
    '${ApiConstants.feedback}/$id/resolve',
    converter: (_) {},
  );

  Future<void> setFeedbackPend(int id) =>
      _http.put<void>('${ApiConstants.feedback}/$id/pend', converter: (_) {});

  Future<void> setFeedbackReject(int id) =>
      _http.put<void>('${ApiConstants.feedback}/$id/reject', converter: (_) {});

  Future<void> setFeedbackVisibility(int id, bool visibility) =>
      _http.put<void>(
        '${ApiConstants.feedback}/$id/visibility?visibility=$visibility',
        converter: (_) {},
        data: {},
      );

  Future<Map<String, dynamic>> postConfigToServer(
    Map<String, dynamic> config,
  ) => _http.post<Map<String, dynamic>>(
    ApiConstants.settings,
    data: config,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> getConfig() => _http.get<Map<String, dynamic>>(
    ApiConstants.settings,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> studyCertificate(Map<String, dynamic> option) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.studyCertificate,
        data: option,
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> sendStudyCertificate(
    Map<String, dynamic> option,
  ) => _http.post<Map<String, dynamic>>(
    ApiConstants.sendStudyCertificate,
    data: option,
    converter: (d) => d as Map<String, dynamic>,
  );

  Future<List<dynamic>> getCampusRecruitment(int page, int size) =>
      _http.get<List<dynamic>>(
        ApiConstants.campusRecruitment,
        converter: (d) => d as List<dynamic>,
        queryParameters: {'page': page, 'size': size},
      );

  Future<Map<String, dynamic>> getRecruitmentDetail(int id) =>
      _http.get<Map<String, dynamic>>(
        '${ApiConstants.campusRecruitment}/$id',
        converter: (d) => d as Map<String, dynamic>,
      );

  // 上传图片到 OSS，并返回最终访问 URL
  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      debugPrint('📸 开始上传图片: $fileName');
      debugPrint('📄 本地文件路径: $filePath');

      // 1. 先签名
      debugPrint('🔐 第1步：获取OSS签名...');
      final sign = await _http.get<Map<String, dynamic>>(
        '${ApiConstants.upload}/signPost',
        converter: (d) => d as Map<String, dynamic>,
        queryParameters: {'type': 'IMAGE'},
      );

      debugPrint('✅ 签名请求成功');
      debugPrint('📋 签名响应: $sign');

      final data = sign['data'] as Map<String, dynamic>;
      final keyPath = (data['keyPath'] as String);
      final ossFilePath = keyPath + fileName;
      debugPrint('🗂️ OSS文件路径: $ossFilePath');

      final policy = data['policy'] as String;
      final ak = data['q-ak'] as String;
      final algorithm = data['q-sign-algorithm'] as String;
      final keyTime = data['q-key-time'] as String;
      final signature = data['q-signature'] as String;

      debugPrint('🔑 签名参数解析完成:');
      debugPrint('  - policy: ${policy.substring(0, 50)}...');
      debugPrint('  - q-ak: $ak');
      debugPrint('  - q-sign-algorithm: $algorithm');
      debugPrint('  - q-key-time: $keyTime');
      debugPrint('  - q-signature: $signature');

      // 获取用户名
      debugPrint('👤 第2步：获取用户信息...');
      final userInfoStr = await _secureStorage.read(key: 'userInfo');
      String username = '';
      if (userInfoStr != null) {
        try {
          final userInfo = json.decode(userInfoStr) as Map<String, dynamic>;
          username = userInfo['name'] ?? '';
          debugPrint('✅ 解析用户名成功: $username');
        } catch (e) {
          debugPrint('❌ 解析用户信息失败: $e');
        }
      } else {
        debugPrint('⚠️ 未找到userInfo');
      }

      // 2. 构造 FormData
      debugPrint('📦 第3步：构造FormData...');
      final formData = FormData.fromMap({
        'key': ossFilePath,
        'policy': policy,
        'q-ak': ak,
        'q-sign-algorithm': algorithm,
        'q-key-time': keyTime,
        'q-signature': signature,
        'x-cos-meta-username': username,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      debugPrint('✅ FormData构造完成:');
      debugPrint('  - key: $ossFilePath');
      debugPrint('  - x-cos-meta-username: $username');
      debugPrint('  - file: $fileName');

      // 3. 构造 Pic-Operations header
      final picOperations = json.encode({
        'is_pic_info': true,
        'rule': [
          {
            'bucket': 'camphor-forest-1327993545',
            'fileid': ossFilePath,
            'rule': 'style/compressed',
          },
        ],
      });

      debugPrint('🎨 Pic-Operations: $picOperations');
      debugPrint('🌐 上传URL: ${ApiConstants.ossUrl}');

      // 3. 直接使用 Dio 进行文件上传
      final dio = (_http as dynamic).dio as Dio;
      final response = await dio.post(
        ApiConstants.ossUrl,
        data: formData,
        options: Options(
          headers: {
            'Pic-Operations': picOperations,
            'Content-Type': 'multipart/form-data',
          },
          responseType: ResponseType.plain, // OSS返回的是XML，不是JSON
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('📬 上传响应状态码: ${response.statusCode}');
      debugPrint('📬 上传响应headers: ${response.headers}');
      debugPrint('📬 上传响应数据: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final finalUrl = '${ApiConstants.dataUrl}$ossFilePath';
        debugPrint('✅ 上传成功！最终URL: $finalUrl');
        return finalUrl;
      } else {
        debugPrint('❌ 上传失败，状态码: ${response.statusCode}');
        debugPrint('❌ 响应内容: ${response.data}');
        throw HttpException(
          response.statusCode ?? 0,
          '图片上传失败: ${response.statusMessage}',
        );
      }
    } catch (e) {
      debugPrint("❌ 图片上传过程中发生异常: $e");
      debugPrint("📍 异常堆栈: ${StackTrace.current}");
      rethrow;
    }
  }

  /// 获取课表数据
  Future<Map<String, dynamic>> fetchClassTable({
    required String xnm,
    required String xqm,
  }) async {
    return await _http.get<Map<String, dynamic>>(
      ApiConstants.classTable,
      converter: (d) => d as Map<String, dynamic>,
      queryParameters: {'xnm': xnm, 'xqm': xqm},
    );
  }

  Future<Map<String, dynamic>> getCourseStatistics(String kch) =>
      _http.get<Map<String, dynamic>>(
        ApiConstants.statistics,
        converter: (d) => d as Map<String, dynamic>,
        queryParameters: {'kch': kch},
      );

  Future<Map<String, dynamic>> updateOpenId(String code) =>
      _http.post<Map<String, dynamic>>(
        ApiConstants.updateOpenId,
        data: {'code': code},
        converter: (d) => d as Map<String, dynamic>,
      );

  Future<List<dynamic>> getFeatures() => _http.get<List<dynamic>>(
    ApiConstants.features,
    converter: (d) => d as List<dynamic>,
  );
}
