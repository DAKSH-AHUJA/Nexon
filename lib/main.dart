import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize Supabase (optional - app works offline without it)
  try {
    await initSupabase();
  } catch (e) {
    // App still works offline without Supabase
    debugPrint('Supabase init failed: $e');
  }

  runApp(
    const ProviderScope(
      child: NexonApp(),
    ),
  );
}
