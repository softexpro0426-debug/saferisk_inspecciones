abstract interface class ArrivalRepository {
  Future<bool> confirmArrival({
    required int aseguradora,
    required String usuario,
    required int nroCaso,
    required DateTime fechaHoraLlegada,
    required String coordenadas,
  });
}
