/// Backend contracts confirmed on 2026-10-02.
/// Keep URLs and new field names here so backend adjustments are localized.
abstract final class PendingApiConfig {
  static const appUpdatesEnabled = bool.fromEnvironment(
    'APP_UPDATES_ENABLED',
    defaultValue: false,
  );

  static const insurerField = 'aseguradora';
  static const workflowField = 'estado_operativo';

  static const startInspectionPath = 'api/IniciaInspeccion';

  static const versionBaseUrl = String.fromEnvironment(
    'APP_VERSION_BASE_URL',
    defaultValue: 'https://sistema.saferisk.ec/flowconnect/',
  );
  static const versionPath = String.fromEnvironment(
    'APP_VERSION_PATH',
    defaultValue: 'api/movil/version',
  );
  static const platformParameter = 'plataforma';
  static const latestVersionField = 'ultima_Version';
  static const latestBuildField = 'ultimo_Build';
  static const minimumBuildField = 'build_Minimo_Permitido';
  static const updateUrlField = 'url_Actualizacion';
  static const releaseNotesField = 'notas';
}
