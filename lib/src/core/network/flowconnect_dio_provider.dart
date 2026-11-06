import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../security/session_lock_controller.dart';
import '../security/device_auth_service.dart';

final flowConnectDioProvider = Provider<Dio>((ref) {
  if (AppConfig.flowConnectApiKey.isEmpty) {
    throw const AppConfigurationException();
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.flowConnectBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'X-Api-Key': AppConfig.flowConnectApiKey,
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!ref.read(sessionLockProvider).isUnlocked) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: const SessionLockedException(),
            ),
          );
          return;
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (value) {
          debugPrint('[FLOWCONNECT] $value');
        },
      ),
    );
  }

  ref.onDispose(() => dio.close());
  return dio;
});
