import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  bool _initialized = false;

  /// AuthProvider bu callback'i register eder. Redis oturumu sunucu tarafında
  /// silindiğinde (başka cihaz girişi, admin logout vb.) otomatik çıkış yapılır.
  static void Function()? onSessionExpired;

  Future<void> init() async {
    if (_initialized) return;
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // JWT token + session-expired interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final data = error.response?.data;
            final isSessionExpired = data is Map && data['sessionExpired'] == true;
            if (isSessionExpired) {
              await SecureStorage.clearAll();
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // SSL doğrulaması — bypass YOK.
    // TÜBITAK kök sertifikası network_security_config.xml üzerinden güvenilir.
    // Geçersiz sertifikalar reddedilir.

    _initialized = true;
  }

  Dio get dio => _dio;

  Future<Response> get(String path,
          {Map<String, dynamic>? params,
          Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters ?? params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(path, data: data);

  Future<Response> postMultipart(String path, {required FormData formData}) =>
      _dio.post(
        path,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

  /// Dosya yükleme URL'i — path traversal koruması ile.
  String buildUploadUrl(String filename) {
    // Yalnızca dosya adını al; dizin geçişlerini temizle
    final safeName = filename.split(RegExp(r'[/\\]')).last;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$base/uploads/$safeName';
  }

  /// Dio hatasını okunabilir Türkçe mesaja çevirir.
  static String parseError(dynamic e) {
    if (e is TimeoutException) {
      return 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Sunucuya bağlanılamadı: Bağlantı zaman aşımı';
        case DioExceptionType.receiveTimeout:
          return 'Sunucu yanıt vermedi: Zaman aşımı';
        case DioExceptionType.sendTimeout:
          return 'Veri gönderilemedi: Zaman aşımı';
        case DioExceptionType.connectionError:
          return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
        case DioExceptionType.badCertificate:
          return 'SSL sertifika hatası. Güvenli bağlantı kurulamadı.';
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final data = e.response?.data;
          String? msg;
          if (data is Map) {
            msg = data['message']?.toString() ?? data['error']?.toString();
          } else if (data is String && data.isNotEmpty) {
            msg = data.length > 200 ? data.substring(0, 200) : data;
          }
          if (statusCode == 401) return 'Oturum süresi doldu, lütfen tekrar giriş yapın';
          if (statusCode == 403) return 'Bu işlem için yetkiniz yok';
          if (statusCode == 404) return 'Kaynak bulunamadı';
          if (statusCode == 429) return 'Çok fazla istek gönderildi, lütfen bekleyin';
          if (statusCode == 500) return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
          return msg ?? 'Sunucu hatası ($statusCode)';
        case DioExceptionType.cancel:
          return 'İstek iptal edildi';
        default:
          return 'Bağlantı hatası';
      }
    }
    if (kDebugMode) return 'Hata: $e';
    return 'Beklenmedik bir hata oluştu';
  }
}
