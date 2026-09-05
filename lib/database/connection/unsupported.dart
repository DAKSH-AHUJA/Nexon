import 'package:drift/drift.dart';

/// Fallback used on platforms that support neither `dart:io` nor
/// `dart:js_interop`.
QueryExecutor openConnection() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}
