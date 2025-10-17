// lib/core/utils/http_client.dart

import 'dart:async';
import 'package:camphor_forest/core/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'i_http_client.dart';

class HttpClient implements IHttpClient {
  final Dio _dio;
  Dio get dio => _dio;

  final FlutterSecureStorage _secureStorage;

  HttpClient({Dio? dio, required FlutterSecureStorage secureStorage})
    : _dio = dio ?? Dio(_createOptions()),
      _secureStorage = secureStorage {
    _setupInterceptors();
  }

  static BaseOptions _createOptions() => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
    headers: ApiConstants.defaultHeaders,
    responseType: ResponseType.json,
  );

  void _setupInterceptors() {
    // 日志拦截
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opts, handler) async {
          debugPrint('🌐 HTTP 请求拦截器: ${opts.path}');

          // 从 secure storage 获取 JWT 和 Cookie
          final token = await _secureStorage.read(key: UserService.jwtKey);
          final slSession = await _secureStorage.read(key: 'sl-session');

          // 构建完整的 Cookie 字符串
          final cookies = <String>[];
          if (token != null && token.isNotEmpty) {
            cookies.add(token);
            debugPrint('🔐 添加 JWT: ${token.substring(0, 20)}...');
          }
          if (slSession != null && slSession.isNotEmpty) {
            cookies.add('sl-session=$slSession');
            debugPrint('🍪 添加 sl-session: $slSession');
          }

          // 如果有 Cookie，则设置请求头
          if (cookies.isNotEmpty) {
            opts.headers['Cookie'] = cookies.join('; ');
            debugPrint('🌈 完整 Cookie: ${opts.headers['Cookie']}');
          }

          return handler.next(opts);
        },
        onResponse: (response, handler) async {
          // 尝试从响应头中提取并保存 Cookie
          final headers = response.headers.map;
          final setCookie = headers['set-cookie'] ?? headers['Set-Cookie'];

          if (setCookie != null) {
            for (final cookie in setCookie) {
              if (cookie.startsWith('DoorKey=')) {
                await _secureStorage.write(
                  key: UserService.jwtKey,
                  value: cookie.split(';').first,
                );
                debugPrint('🔑 更新 JWT: ${cookie.substring(0, 50)}...');
              }
            }
          }

          return handler.next(response);
        },
        onError: (DioException err, handler) async {
          debugPrint('❌ HTTP 请求错误: ${err.type}, ${err.response?.statusCode}');

          // SSL证书错误特殊处理
          if (err.message?.contains('CERTIFICATE_VERIFY_FAILED') == true ||
              err.message?.contains('certificate has expired') == true) {
            debugPrint('🔒 SSL证书错误：服务器证书可能已过期，请联系管理员');
          }

          // 401 处理：清理 Token 并重定向到登录
          if (err.response?.statusCode == 401) {
            debugPrint('🚨 401 未授权，清理 Token');
            await _secureStorage.deleteAll();
          }

          return handler.next(err);
        },
      ),
    );
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  }) => _request(
    () => _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: responseType, headers: headers),
    ),
    converter,
  );

  @override
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  }) => _request(
    () => _dio.post(
      path,
      data: data,
      options: Options(responseType: responseType, headers: headers),
    ),
    converter,
  );

  @override
  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  }) => _request(
    () => _dio.put(
      path,
      data: data,
      options: Options(responseType: responseType, headers: headers),
    ),
    converter,
  );

  @override
  Future<T> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  }) => _request(
    () => _dio.delete(
      path,
      data: data,
      options: Options(responseType: responseType, headers: headers),
    ),
    converter,
  );

  Future<T> _request<T>(
    Future<Response> Function() dioCall,
    T Function(dynamic data)? converter,
  ) async {
    try {
      final resp = await dioCall();
      final status = resp.statusCode ?? 0;
      final body = resp.data;
      if (status >= 200 && status < 300) {
        if (converter != null) {
          return converter(body);
        }
        return body as T;
      }
      throw HttpException(status, resp.statusMessage ?? '未知错误');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout) {
      return TimeoutException('请求超时');
    }
    final code = e.response?.statusCode;
    switch (code) {
      case 400:
        return BadRequestException('错误请求');
      case 401:
        return UnauthorizedException('未授权');
      case 403:
        return ForbiddenException('禁止访问');
      case 404:
        return NotFoundException('资源未找到');
      case 500:
        return ServerException('服务器错误');
    }
    if (e.type == DioExceptionType.cancel) {
      return CancelledException('请求已取消');
    }
    return NetworkException(e.message ?? '未知网络错误');
  }
}

/// HTTP 异常
class HttpException implements Exception {
  final int statusCode;
  final String message;
  HttpException(this.statusCode, this.message);
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class CancelledException implements Exception {
  final String message;
  CancelledException(this.message);
}
