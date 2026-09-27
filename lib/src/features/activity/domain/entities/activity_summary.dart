import 'activity_case.dart';

final class ActivitySummary {
  const ActivitySummary({required this.pending, required this.completed});

  final List<ActivityCase> pending;
  final List<ActivityCase> completed;

  int get pendingCount => pending.length;

  int completedToday(DateTime now) {
    return completed.where((item) {
      final date = item.fechaFin;

      if (date == null) {
        return false;
      }

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }
}
