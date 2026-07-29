import 'package:intl/intl.dart';

class AppDateUtils {
  static String format(String? isoDate) => formatDate(isoDate);

  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'Az önce';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return formatDate(isoDate);
    } catch (_) {
      return isoDate;
    }
  }
}
