// Native platform SQLite initialization
// This file is used when running on Windows, Linux, macOS, iOS, Android

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeSqflite() {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // iOS, macOS, Android use native sqflite - no FFI needed
}
