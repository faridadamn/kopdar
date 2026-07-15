import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../../config/constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  Future<String?>? _refreshFuture;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      _SafeLogInterceptor(),
    ]);
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await _dio.post(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await _dio.put(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await _dio.delete(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String?> refreshAccessToken() {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    final completer = Completer<String?>();
    _refreshFuture = completer.future;
    _performRefresh().then(completer.complete).catchError(completer.completeError)
      .whenComplete(() => _refreshFuture = null);
    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await SecureStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await Dio(BaseOptions(baseUrl: AppConstants.baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>?;
      final accessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String?;
      if (accessToken == null || newRefreshToken == null) return null;

      await SecureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } catch (_) {
      await SecureStorage.clearTokens();
      return null;
    }
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Koneksi timeout. Silakan coba lagi.');
      case DioExceptionType.connectionError:
        return NetworkException('Tidak ada koneksi internet.');
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return NetworkException('Request dibatalkan.');
      default:
        return NetworkException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    String message = 'Terjadi kesalahan.';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(message);
      case 401:
        return UnauthorizedException('Sesi habis. Silakan masuk kembali.');
      case 403:
        return ForbiddenException('Anda tidak memiliki akses.');
      case 404:
        return NotFoundException('Data tidak ditemukan.');
      case 409:
        return ConflictException(message);
      case 500:
      case 502:
      case 503:
        return ServerException('Server sedang bermasalah. Coba beberapa saat lagi.');
      default:
        return ServerException(message);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient client;

  _AuthInterceptor(this.client);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra['auth_retried'] == true;
    final isAuthEndpoint = err.requestOptions.path.contains('/auth/');

    if (err.response?.statusCode == 401 && !alreadyRetried && !isAuthEndpoint) {
      final newToken = await client.refreshAccessToken();
      if (newToken != null) {
        final opts = err.requestOptions;
        opts.extra['auth_retried'] = true;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await client.dio.fetch(opts);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }
    handler.next(err);
  }
}

class _SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      print('[API] ${response.statusCode} ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      print('[API ERROR] ${err.requestOptions.path}: ${err.response?.statusCode}');
      return true;
    }());
    handler.next(err);
  }
}
