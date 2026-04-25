final Map<int, Set<DateTime>> _holidayCache = {};

/// Brazilian national (federal) holidays for [year].
/// All dates are midnight-normalised (no time component).
///
/// Fixed  : Jan 1, Apr 21, May 1, Sep 7, Oct 12, Nov 2, Nov 15, Dec 25
///          Nov 20 from 2024 (Lei 14.759/2023 — Consciência Negra)
/// Moveable: Good Friday (Easter − 2 days), Corpus Christi (Easter + 60 days)
///
/// Carnaval is not a federal holiday and is intentionally excluded.
Set<DateTime> getBrazilianHolidays(int year) {
  if (_holidayCache.containsKey(year)) return _holidayCache[year]!;

  final easter = _easterDate(year);

  final holidays = <DateTime>{
    DateTime(year, 1, 1),
    DateTime(year, 4, 21),
    DateTime(year, 5, 1),
    DateTime(year, 9, 7),
    DateTime(year, 10, 12),
    DateTime(year, 11, 2),
    DateTime(year, 11, 15),
    DateTime(year, 12, 25),
    easter.subtract(const Duration(days: 2)), // Sexta-feira Santa
    easter.add(const Duration(days: 60)),     // Corpus Christi
  };

  if (year >= 2024) holidays.add(DateTime(year, 11, 20));

  _holidayCache[year] = holidays;
  return holidays;
}

/// Returns true if [date] falls on a Brazilian national holiday.
/// The time component of [date] is ignored.
bool isBrazilianHoliday(DateTime date) {
  final normalised = DateTime(date.year, date.month, date.day);
  return getBrazilianHolidays(date.year).contains(normalised);
}

/// Meeus/Jones/Butcher algorithm — returns Easter Sunday for [year].
DateTime _easterDate(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}
