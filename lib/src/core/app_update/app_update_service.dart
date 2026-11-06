import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/pending_api_config.dart';
import '../config/app_config.dart';
import 'app_version_policy.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  // FlowConnect API key, independent of user sessions and their 401 interceptor.
  final dio = Dio(
    BaseOptions(
      baseUrl: PendingApiConfig.versionBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Accept': 'application/json',
        'X-Api-Key': AppConfig.flowConnectApiKey,
      },
      responseType: ResponseType.json,
    ),
  );
  ref.onDispose(() => dio.close());
  return AppUpdateService(dio);
});

final class AppUpdateService {
  const AppUpdateService(this._dio);
  final Dio _dio;

  Future<AppUpdateDecision?> check() async {
    if (!PendingApiConfig.appUpdatesEnabled || kIsWeb) return null;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platform == null) return null;

    final package = await PackageInfo.fromPlatform();
    final installed = int.tryParse(package.buildNumber);
    if (installed == null || installed < 1) return null;
    final cacheKey = 'app_version_policy_v2_${package.packageName}_$platform';
    AppVersionPolicy? policy;
    var cached = false;
    try {
      final response = await _dio
          .get<dynamic>(
            PendingApiConfig.versionPath,
            queryParameters: {PendingApiConfig.platformParameter: platform},
          )
          .timeout(const Duration(seconds: 6));
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Respuesta de versión inválida.');
      }
      final policies = data
          .map((entry) {
            if (entry is! Map<String, dynamic>) {
              throw const FormatException('Registro de versión inválido.');
            }
            return AppVersionPolicy.fromJson(entry);
          })
          .where((entry) => entry.platform == platform)
          .toList(growable: false);
      if (policies.length != 1) {
        throw const FormatException(
          'No existe una política única para esta plataforma.',
        );
      }
      final parsed = policies.single;
      if (parsed.platform != platform) {
        throw const FormatException('Plataforma de versión incorrecta.');
      }
      policy = parsed;
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(cacheKey, jsonEncode(parsed.toJson()));
      } catch (_) {
        // A valid policy still applies when writing its cache fails.
      }
    } catch (_) {
      try {
        final preferences = await SharedPreferences.getInstance();
        final saved = preferences.getString(cacheKey);
        if (saved != null) {
          final data = jsonDecode(saved);
          if (data is Map<String, dynamic>) {
            final parsed = AppVersionPolicy.fromJson(data);
            if (parsed.platform == platform) {
              policy = parsed;
              cached = true;
            }
          }
        }
      } catch (_) {
        // No verified restriction: fail open, never lock out on malformed data.
      }
    }
    if (policy == null) return null;
    final decision = AppUpdateDecision(
      policy: policy,
      installedBuild: installed,
      fromCache: cached,
    );
    return decision.available ? decision : null;
  }
}
