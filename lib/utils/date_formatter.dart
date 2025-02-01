import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return 'Just now';
      }
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  if (date.year == now.year) {
    return DateFormat('MMM d').format(date);
  }

  return DateFormat('MMM d, y').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('MMM d, y HH:mm').format(date);
}

String formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year) {
    if (start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, y').format(end)}';
    }
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(end)}';
  }
  return '${DateFormat('MMM d, y').format(start)} - ${DateFormat('MMM d, y').format(end)}';
}

String formatTimeOfDay(DateTime date) {
  return DateFormat('HH:mm').format(date);
} 