import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionExpiredProvider = NotifierProvider<SessionExpired, bool>(
  SessionExpired.new,
);

final class SessionExpired extends Notifier<bool> {
  @override
  bool build() => false;

  void expire() => state = true;
  void reset() => state = false;
}
