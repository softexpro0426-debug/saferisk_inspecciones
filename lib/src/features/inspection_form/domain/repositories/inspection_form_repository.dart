abstract interface class InspectionFormRepository {
  Future<bool> concludeService({
    required int aseguradora,
    required String usuario,
    required int nroCaso,
  });
}
