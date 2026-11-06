import '../config/pending_api_config.dart';

final class AppVersionPolicy {
  const AppVersionPolicy({
    required this.platform,
    required this.version,
    required this.latestBuild,
    required this.minimumBuild,
    required this.url,
    required this.notes,
  });

  final String platform;
  final String version;
  final int latestBuild;
  final int minimumBuild;
  final Uri url;
  final String notes;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    final platform = json[PendingApiConfig.platformParameter];
    final version = json[PendingApiConfig.latestVersionField];
    final latest = json[PendingApiConfig.latestBuildField];
    final minimum = json[PendingApiConfig.minimumBuildField];
    final rawUrl = json[PendingApiConfig.updateUrlField];
    final notes = json[PendingApiConfig.releaseNotesField];
    final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if ((platform != 'android' && platform != 'ios') ||
        version is! String ||
        version.trim().isEmpty ||
        latest is! int ||
        minimum is! int ||
        latest < 1 ||
        minimum < 1 ||
        minimum > latest ||
        url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        (notes != null && notes is! String)) {
      throw const FormatException('Política de versión inválida.');
    }
    return AppVersionPolicy(
      platform: platform as String,
      version: version,
      latestBuild: latest,
      minimumBuild: minimum,
      url: url,
      notes: notes as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    PendingApiConfig.platformParameter: platform,
    PendingApiConfig.latestVersionField: version,
    PendingApiConfig.latestBuildField: latestBuild,
    PendingApiConfig.minimumBuildField: minimumBuild,
    PendingApiConfig.updateUrlField: url.toString(),
    PendingApiConfig.releaseNotesField: notes,
  };
}

final class AppUpdateDecision {
  const AppUpdateDecision({
    required this.policy,
    required this.installedBuild,
    this.fromCache = false,
  });
  final AppVersionPolicy policy;
  final int installedBuild;
  final bool fromCache;

  bool get required => installedBuild < policy.minimumBuild;
  bool get available => installedBuild < policy.latestBuild;
}
