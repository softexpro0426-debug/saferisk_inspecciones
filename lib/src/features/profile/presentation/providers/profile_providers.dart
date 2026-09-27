import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/network/network_providers.dart';

final profileSessionProvider = FutureProvider((ref) {
  return ref.watch(sessionStorageProvider).readSession();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = Connectivity();

  final initial = await connectivity.checkConnectivity();

  yield initial;

  yield* connectivity.onConnectivityChanged;
});
