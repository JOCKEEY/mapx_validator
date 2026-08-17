// A PIN always has a fixed shape: 5 numeric groups joined by 4 hyphens
// (e.g. "049-05-0001-040-21"). TD/ARP number formats vary by municipality
// and can't be pattern-matched, so anything that isn't PIN-shaped is
// treated as a TD number.
final RegExp _pinPattern = RegExp(r'^\d+(-\d+){4}$');

/// Splits a comma-separated search query into trimmed, deduplicated,
/// non-empty tokens and rejoins them for sending to the API.
String cleanSearchQuery(String rawQuery) {
  final tokens = rawQuery
      .split(',')
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toSet()
      .toList();
  return tokens.join(',');
}

/// Auto-detects the `searchBy` value ('pin' or 'tdnumber') from the query.
/// Only the first token is inspected since a batch search is expected to
/// be all one type.
String detectSearchBy(String cleanedQuery) {
  final tokens = cleanedQuery.split(',');
  final firstToken = tokens.isEmpty ? '' : tokens.first;
  return _pinPattern.hasMatch(firstToken) ? 'pin' : 'tdnumber';
}
