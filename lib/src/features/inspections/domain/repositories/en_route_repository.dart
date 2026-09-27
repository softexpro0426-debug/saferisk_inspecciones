abstract interface class EnRouteRepository {
  Future<void> markEnRoute({
    required String user,
    required int insurerCode,
    required int caseNumber,
    required String coordinates,
  });
}
