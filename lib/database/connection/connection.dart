/// Platform-aware database connection selector.
///
/// On the web (and other JS platforms) this resolves to the sql.js-backed
/// [WebDatabase]; on native platforms (Windows, Linux, macOS, Android, iOS)
/// it resolves to a native sqlite3 connection using the libraries bundled by
/// `sqlite3_flutter_libs`. On any other platform it throws at runtime.
library;

export 'unsupported.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.io) 'native.dart';
