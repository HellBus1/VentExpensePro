import 'package:intl/intl.dart';

/// Utilities for consistent date formatting across the app.
class DateFormatter {
  DateFormatter._();

  /// Full date: "21 February 2026"
  static String full(DateTime date) => DateFormat('d MMMM yyyy').format(date);

  /// Short date: "21 Feb 2026"
  static String short(DateTime date) => DateFormat('d MMM yyyy').format(date);

  /// Day and month only: "21 Feb"
  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  /// Time only: "14:30"
  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  /// Relative day label: "Today", "Yesterday", or short date.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date); // "Monday"
    return short(date);
  }

  /// Group header label for the receipt feed.
  static String receiptHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today, ${dayMonth(date)}';
    if (diff == 1) return 'Yesterday, ${dayMonth(date)}';
    return '${DateFormat('EEEE').format(date)}, ${dayMonth(date)}';
  }
}
