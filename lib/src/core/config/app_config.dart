import 'dart:convert';

import 'package:flutter/services.dart';

abstract final class AppConfig {
  static const String appName = 'SafeRisk Inspecciones';

  // API antigua / principal
  static const String apiBaseUrl = 'https://sistema.saferisk.ec/SW_APP/';

  // API FlowConnect
  static const String flowConnectBaseUrl =
      'https://sistema.saferisk.ec/flowconnect/';

  static const String _definedFlowConnectApiKey = String.fromEnvironment(
    'FLOWCONNECT_API_KEY',
  );

  static String _localFlowConnectApiKey = '';

  static String get flowConnectApiKey =>
      _definedFlowConnectApiKey.trim().isNotEmpty
      ? _definedFlowConnectApiKey.trim()
      : _localFlowConnectApiKey;

  static Future<void> loadLocalConfiguration() async {
    if (_definedFlowConnectApiKey.trim().isNotEmpty) return;
    try {
      final text = await rootBundle.loadString('config/local.json');
      final data = jsonDecode(text);
      final value = data is Map<String, dynamic>
          ? data['FLOWCONNECT_API_KEY']
          : null;
      _localFlowConnectApiKey = value is String ? value.trim() : '';
    } catch (_) {
      // Keep the login available; FlowConnect reports a configuration error.
      _localFlowConnectApiKey = '';
    }
  }

  static const Duration connectTimeout = Duration(seconds: 10);

  static const Duration receiveTimeout = Duration(seconds: 20);

  static const Duration sendTimeout = Duration(seconds: 20);
}

final class AppConfigurationException implements Exception {
  const AppConfigurationException();
}
