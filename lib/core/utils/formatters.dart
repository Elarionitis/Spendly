import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: '₹',
    decimalDigits: 1,
  );

  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _shortDateFormat = DateFormat('d MMM');
  static final _monthYearFormat = DateFormat('MMMM yyyy');
  static final _timeFormat = DateFormat('h:mm a');

  /// Format as currency: ₹1,234.56
  static String currency(double amount) => _currencyFormat.format(amount);

  /// Format as compact currency: ₹1.2K
  static String compactCurrency(double amount) =>
      _compactCurrencyFormat.format(amount);

  /// Format date: Mar 7, 2026
  static String date(DateTime date) => _dateFormat.format(date);

  /// Alias for date — full date string (Mar 7, 2026)
  static String fullDate(DateTime date) => _dateFormat.format(date);

  /// Format short date: 7 Mar
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format month year: March 2026
  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format time: 2:30 PM
  static String time(DateTime date) => _timeFormat.format(date);

  /// Relative date: Today, Yesterday, or date string
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return AppFormatters.date(date);
  }

  /// Format percentage: 45.5%
  static String percentage(double value) =>
      '${value.toStringAsFixed(1)}%';
}
