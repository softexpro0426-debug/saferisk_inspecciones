import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_store_links.dart';

final class AppStoreLauncher {
  const AppStoreLauncher();

  Future<void> openBrokerStore() async {
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.android => Uri.parse(AppStoreLinks.brokerAndroid),
      TargetPlatform.iOS => Uri.parse(AppStoreLinks.brokerIos),
      _ => throw UnsupportedError(
        'Plataforma no soportada para abrir la tienda.',
      ),
    };

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      throw StateError('No fue posible abrir la tienda de aplicaciones.');
    }
  }
}
