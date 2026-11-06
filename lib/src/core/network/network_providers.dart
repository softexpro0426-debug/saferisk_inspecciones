import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../config/app_config.dart';
import '../security/session_storage.dart';
import '../security/session_expired.dart';
import '../security/session_lock_controller.dart';
import '../security/device_auth_service.dart';
import '../security/secure_storage_provider.dart';

export '../security/secure_storage_provider.dart' show secureStorageProvider;

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(
    ref.watch(secureStorageProvider),
    ref.read(sessionLockProvider.notifier),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
    ),
  );

  var expiring = false;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path != 'api/Ingreso' &&
            !ref.read(sessionLockProvider).isUnlocked) {
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
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != 'api/Ingreso' &&
            !expiring) {
          expiring = true;
          try {
            await ref.read(sessionStorageProvider).clearSession();
          } catch (_) {
            // The original HTTP error is still delivered to its caller.
          } finally {
            if (ref.mounted) {
              ref.read(sessionExpiredProvider.notifier).expire();
            }
            expiring = false;
            handler.next(error);
          }
          return;
        }
        handler.next(error);
      },
    ),
  );
  ref.onDispose(() => dio.close());
  return dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});
