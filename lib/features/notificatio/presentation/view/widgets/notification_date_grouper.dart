// utils/notification_date_grouper.dart

import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:intl/intl.dart';

/// Groups a flat list of notifications by date section headers.
/// Returns a mixed list of [String] (headers) and [NotificationModel] items.
class NotificationDateGrouper {
  NotificationDateGrouper._();

  static List<dynamic> group(List<NotificationModel> notifications) {
    final result = <dynamic>[];
    String? lastLabel;

    for (final n in notifications) {
      final label = _dateLabel(n.createdAt);
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  static String _dateLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM d, yyyy').format(dt);
  }
}