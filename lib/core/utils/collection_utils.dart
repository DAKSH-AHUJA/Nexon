/// Small collection helpers used by the Riverpod state classes.
extension IterableUtils<T> on Iterable<T> {
  /// Like [firstWhere] but returns `null` instead of throwing.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Returns `true` when [query] is empty or any of [fields] contains it,
/// case-insensitively.
bool matchesQuery(String query, List<String> fields) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return fields.any((field) => field.toLowerCase().contains(q));
}
