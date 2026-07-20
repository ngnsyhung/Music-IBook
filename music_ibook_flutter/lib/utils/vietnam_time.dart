class VietnamTime {
  static const offset = Duration(hours: 7);

  static DateTime? parseUtc(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final hasZone =
        value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
    return DateTime.tryParse(hasZone ? value : '${value}Z')?.toUtc();
  }

  static DateTime toVietnam(DateTime utc) => utc.toUtc().add(offset);

  static String format(DateTime utc, {bool includeSeconds = false}) {
    final value = toVietnam(utc);
    String two(int number) => number.toString().padLeft(2, '0');
    final seconds = includeSeconds ? ':${two(value.second)}' : '';
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}$seconds (UTC+7)';
  }
}
