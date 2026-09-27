import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';

import "../../data/datasource/activity_remote_data_source.dart";
import '../../domain/entities/activity_case.dart';
import '../../domain/entities/activity_summary.dart';

final activityRemoteDataSourceProvider = Provider<ActivityRemoteDataSource>((
  ref,
) {
  return ActivityRemoteDataSource(ref.watch(dioProvider));
});

final activityControllerProvider =
    AsyncNotifierProvider<ActivityController, ActivitySummary>(
      ActivityController.new,
    );

final class ActivityController extends AsyncNotifier<ActivitySummary> {
  @override
  Future<ActivitySummary> build() {
    return _load();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading<ActivitySummary>();

    state = await AsyncValue.guard(_load);
  }

  Future<ActivitySummary> _load() async {
    final session = await ref.read(sessionStorageProvider).readSession();

    if (session == null) {
      throw const ActivityException('No existe una sesión activa.');
    }

    try {
      final dataSource = ref.read(activityRemoteDataSourceProvider);

      final responses = await Future.wait<List<ActivityCase>>([
        dataSource.getCases(usuario: session.usuario, tipoConsulta: 'C'),
        dataSource.getCases(usuario: session.usuario, tipoConsulta: 'P'),
      ]);

      final pending = responses[0];
      final completed = responses[1];

      return ActivitySummary(pending: pending, completed: completed);
    } on DioException catch (error) {
      throw ActivityException(_mapDioError(error));
    }
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'SafeRisk está tardando demasiado en responder.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No fue posible conectarse con SafeRisk.';
    }

    return switch (error.response?.statusCode) {
      401 => 'Tu sesión ya no está autorizada.',
      403 => 'No tienes autorización para consultar esta información.',
      int code when code >= 500 =>
        'SafeRisk no está disponible en este momento.',
      _ => 'No fue posible cargar la actividad.',
    };
  }
}

final class ActivityException implements Exception {
  const ActivityException(this.message);

  final String message;

  @override
  String toString() => message;
}
