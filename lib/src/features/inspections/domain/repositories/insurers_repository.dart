import '../entities/insurer.dart';

abstract interface class InsurersRepository {
  Future<List<Insurer>> getInsurers({required String usuario});
}
