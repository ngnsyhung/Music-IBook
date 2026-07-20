import 'package:flutter_test/flutter_test.dart';
import 'package:music_ibook_flutter/utils/vietnam_time.dart';

void main() {
  test('parses an unspecified server timestamp as UTC', () {
    final timestamp = VietnamTime.parseUtc('2026-07-20T01:30:45');

    expect(timestamp, DateTime.utc(2026, 7, 20, 1, 30, 45));
    expect(
      VietnamTime.format(timestamp!, includeSeconds: true),
      '20/07/2026 08:30:45 (UTC+7)',
    );
  });

  test('preserves an explicitly zoned timestamp', () {
    final timestamp = VietnamTime.parseUtc('2026-07-20T08:30:00+07:00');

    expect(timestamp, DateTime.utc(2026, 7, 20, 1, 30));
    expect(VietnamTime.format(timestamp!), '20/07/2026 08:30 (UTC+7)');
  });
}
