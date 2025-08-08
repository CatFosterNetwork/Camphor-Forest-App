import 'package:dio/dio.dart';

/// HTTP 客户端抽象——所有请求只暴露泛型 T，不暴露 Dio 细节
abstract class IHttpClient {
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  });

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  });

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  });

  Future<T> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
  });
}
