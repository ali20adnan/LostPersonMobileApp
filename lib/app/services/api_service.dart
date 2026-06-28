import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';

/// HTTP API client service for communicating with the backend
class ApiService extends GetxService {
  static const _tokenKey = 'jwt_access_token';
  // first_unlock keeps the token readable at app launch (incl. right after a
  // reboot, before the first manual unlock) so the saved session survives.
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final _client = http.Client();

  String get _baseUrl => ApiConstants.apiBaseUrl;

  // ── Token Management ──────────────────────────────────────────

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── Headers ───────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Core HTTP Methods ─────────────────────────────────────────

  Future<ApiResponse> get(String endpoint,
      {Map<String, String>? queryParams,
      Map<String, List<String>>? multiQueryParams}) async {
    try {
      final uri = _buildUriMulti(endpoint, queryParams, multiQueryParams);
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  Future<ApiResponse> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .post(uri,
              headers: await _headers(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  Future<ApiResponse> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .patch(uri,
              headers: await _headers(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  Future<ApiResponse> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .put(uri,
              headers: await _headers(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .delete(uri, headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  /// Upload multipart form data with files (POST)
  Future<ApiResponse> multipartPost(
    String endpoint, {
    Map<String, String>? fields,
    List<MultipartFile>? files,
  }) =>
      _multipartRequest('POST', endpoint, fields: fields, files: files);

  /// Upload multipart form data with files (PATCH)
  Future<ApiResponse> multipartPatch(
    String endpoint, {
    Map<String, String>? fields,
    List<MultipartFile>? files,
  }) =>
      _multipartRequest('PATCH', endpoint, fields: fields, files: files);

  /// Shared implementation for multipart requests
  Future<ApiResponse> _multipartRequest(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    List<MultipartFile>? files,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest(method, uri);

      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null) request.fields.addAll(fields);

      if (files != null) {
        for (final file in files) {
          request.files.add(await http.MultipartFile.fromPath(
            file.field,
            file.path,
            contentType:
                file.mimeType != null ? MediaType.parse(file.mimeType!) : null,
          ));
        }
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on HttpException {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    } catch (e) {
      return ApiResponse.error('خطأ غير متوقع: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    return _buildUriMulti(endpoint, queryParams, null);
  }

  Uri _buildUriMulti(String endpoint, Map<String, String>? queryParams,
      Map<String, List<String>>? multiQueryParams) {
    final url = '$_baseUrl$endpoint';
    final parts = <String>[];
    queryParams?.forEach((k, v) {
      parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
    });
    multiQueryParams?.forEach((k, vs) {
      for (final v in vs) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
      }
    });
    if (parts.isEmpty) return Uri.parse(url);
    return Uri.parse('$url?${parts.join('&')}');
  }

  ApiResponse _handleResponse(http.Response response) {
    debugPrint(
        'ApiService: ${response.request?.method} ${response.request?.url} → ${response.statusCode}');

    if (response.statusCode == 401) {
      // A 401 from the login endpoint itself means wrong credentials; surface
      // a clear message and let the LoginPage stay mounted (redirecting to
      // /login while already on it would dispose the AuthController and its
      // TextEditingControllers, replacing the inputs with the global
      // ErrorWidget.builder fallback).
      final isLoginRequest =
          response.request?.url.path.endsWith('/auth/login') ?? false;
      if (isLoginRequest) {
        return ApiResponse.error(
            'اسم المستخدم أو كلمة المرور غير صحيحة',
            statusCode: 401);
      }
      // Token expired or invalid → redirect to login
      deleteToken();
      Get.offAllNamed('/login');
      return ApiResponse.error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً',
          statusCode: 401);
    }

    dynamic data;
    try {
      data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(data, statusCode: response.statusCode);
    }

    // Extract error message from response
    String message = 'حدث خطأ في الخادم';
    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;
      if (data['message'] is List) {
        message = (data['message'] as List).join(', ');
      }
    }

    return ApiResponse.error(message, statusCode: response.statusCode);
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}

/// Wrapper for API responses
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? errorMessage;
  final int? statusCode;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data, {int? statusCode}) =>
      ApiResponse._(isSuccess: true, data: data, statusCode: statusCode);

  factory ApiResponse.error(String message, {int? statusCode}) =>
      ApiResponse._(
          isSuccess: false, errorMessage: message, statusCode: statusCode);
}

/// Simple descriptor for a file to attach in multipart upload
class MultipartFile {
  final String field;
  final String path;
  final String? mimeType;

  const MultipartFile({
    required this.field,
    required this.path,
    this.mimeType,
  });
}
