/// Matches "New M-PESA balance is Ksh522.23" (also "Ksh 522.23", any case) and
/// balance-check replies: "balance was: M-PESA Account : Ksh522.23 Business ...".
final _balance = RegExp(
  r'balance\s+(?:is|was:?)\s+(?:M-PESA Account\s*:\s*)?Ksh\s?([\d,]+\.\d{2})',
  caseSensitive: false,
);

/// The account balance in [body], e.g. `Ksh522.23` -> `522.23`, or null when
/// the message carries none (Fuliza notices, failed transactions, ...).
String? parseBalance(String body) => _balance.firstMatch(body)?.group(1);

/// Balance from the newest message that has one. [messagesNewestFirst] is the
/// order returned by `readMpesaMessages()`.
String? latestBalance(Iterable<String> messagesNewestFirst) {
  for (final body in messagesNewestFirst) {
    final b = parseBalance(body);
    if (b != null) return b;
  }
  return null;
}
