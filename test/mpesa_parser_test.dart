import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_fun/src/mpesa_parser.dart';

void main() {
  test('parses balance variants', () {
    expect(parseBalance('X Confirmed. Ksh10.00 paid to A. New M-PESA balance is Ksh522.23. Transaction cost'), '522.23');
    expect(parseBalance('New M-PESA balance is Ksh 1,522.23.'), '1,522.23');
    expect(parseBalance('Failed, you have entered the wrong PIN.'), isNull);
  });

  // Runs only where the private fixture (git-ignored) exists.
  final fixture = File('test/fixtures/mpesa_messages.jsonl');
  test('every non-Fuliza/non-failure message yields a balance', () {
    final bodies = fixture
        .readAsLinesSync()
        .map((l) => (jsonDecode(l) as Map)['body'] as String);
    final misses = bodies.where((b) =>
        parseBalance(b) == null &&
        b.contains('Confirmed') &&
        !b.contains('Fuliza'));
    expect(misses, isEmpty);
  }, skip: fixture.existsSync() ? false : 'fixture not present');
}
