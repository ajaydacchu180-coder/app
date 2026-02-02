import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/platform_sync.dart';

// Conditional import for sqflite - web gets stub, native gets real implementation
import 'src/services/sqflite_stub.dart'
    if (dart.library.io) 'src/services/sqflite_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop platforms (safe on web - uses stub)
  initializeSqflite();

  // Initialize platform background sync scaffolding (WorkManager) — safe no-op on platforms
  await PlatformSync.initialize();
  runApp(const ProviderScope(child: EnterpriseApp()));
}
