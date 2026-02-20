import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  final String locale;

  DateFormatter(this.locale);

  /// "Wednesday, January 15" - for screen headers
  String formatFullDate(DateTime date) =>
      DateFormat.yMMMMd(locale).format(date);

  /// "January 2025" - for calendar month headers
  String formatMonthYear(DateTime date) =>
      DateFormat.yMMMM(locale).format(date);

  /// "14:30" - for meal timestamps
  String formatTime(DateTime date) => DateFormat.Hm(locale).format(date);

  /// "Jan 15" - for date groups
  String formatShortDate(DateTime date) => DateFormat.MMMd(locale).format(date);

  /// "Wednesday" - for weekday name
  String formatWeekday(DateTime date) => DateFormat.EEEE(locale).format(date);
}

extension DateFormatterContext on BuildContext {
  DateFormatter get dateFormatter {
    final locale = Localizations.localeOf(this).toString();
    return DateFormatter(locale);
  }
}
