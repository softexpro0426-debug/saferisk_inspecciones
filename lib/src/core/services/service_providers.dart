import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_store_launcher.dart';

final appStoreLauncherProvider = Provider<AppStoreLauncher>((ref) {
  return const AppStoreLauncher();
});
