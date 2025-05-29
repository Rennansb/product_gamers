// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static final _fixtureDateTimeFormat = DateFormat('dd/MM HH:mm', 'pt_BR');
  static final _fullDateTimeFormat = DateFormat(
    'EEEE, dd MMMM yyyy HH:mm',
    'pt_BR',
  );
  static final _yearFormat = DateFormat('yyyy', 'pt_BR');
  static final _timeFormat = DateFormat.Hm('pt_BR'); // Só Hora:Minuto
  static final _dayMonthFormat = DateFormat('dd/MM', 'pt_BR');

  /// Formata para "dd/MM HH:mm" (ex: "25/12 16:00")
  static String formatFixtureDate(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    return _fixtureDateTimeFormat.format(localDateTime);
  }

  /// Formata para "EEEE, dd MMMM yyyy HH:mm" (ex: "Terça-feira, 25 Dezembro 2023 16:00")
  static String formatFullDate(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    return _fullDateTimeFormat.format(localDateTime);
  }

  /// Retorna o ano como string (ex: "2023")
  static String getYear(DateTime dateTime) {
    return _yearFormat.format(dateTime.toLocal());
  }

  /// Formata para "HH:mm" (ex: "16:00")
  static String formatTimeOnly(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Formata para "dd/MM" (ex: "25/12")
  static String formatDayMonth(DateTime dateTime) {
    return _dayMonthFormat.format(dateTime.toLocal());
  }

  /// Retorna "Hoje HH:mm", "Amanhã HH:mm" ou "dd/MM HH:mm"
  static String formatRelativeDateWithTime(DateTime dateTime) {
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateToCompare = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );

    if (dateToCompare == today) {
      return "Hoje ${_timeFormat.format(localDateTime)}";
    } else if (dateToCompare == tomorrow) {
      return "Amanhã ${_timeFormat.format(localDateTime)}";
    } else {
      return _fixtureDateTimeFormat.format(localDateTime);
    }
  }
}
