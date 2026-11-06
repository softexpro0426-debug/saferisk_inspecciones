import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/secure_storage_provider.dart';
import 'terms_document.dart';

final termsAcceptanceStoreProvider = Provider<TermsAcceptanceStore>((ref) {
  return TermsAcceptanceStore(ref.watch(secureStorageProvider));
});

final class TermsAcceptanceStore {
  const TermsAcceptanceStore(this._storage);
  final FlutterSecureStorage _storage;

  String _key(String usuario) =>
      'terms_acceptance_v1_'
      '${Uri.encodeComponent(usuario)}_${TermsDocument.id}_'
      '${TermsDocument.version}_${TermsDocument.fingerprint}';

  Future<bool> hasAccepted(String usuario) async {
    final text = await _storage.read(key: _key(usuario));
    if (text == null) return false;
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return false;
      final date = data['acceptedAtUtc'];
      return data['usuario'] == usuario &&
          data['documentId'] == TermsDocument.id &&
          data['version'] == TermsDocument.version &&
          data['sha256'] == TermsDocument.fingerprint &&
          data['accepted'] == true &&
          date is String &&
          DateTime.tryParse(date) != null;
    } on FormatException {
      return false;
    }
  }

  Future<void> accept(String usuario) async {
    await _storage.write(
      key: _key(usuario),
      value: jsonEncode({
        'usuario': usuario,
        'documentId': TermsDocument.id,
        'version': TermsDocument.version,
        'sha256': TermsDocument.fingerprint,
        'accepted': true,
        'acceptedAtUtc': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (!await hasAccepted(usuario)) {
      throw StateError('No se pudo verificar el registro de aceptación.');
    }
  }
}
