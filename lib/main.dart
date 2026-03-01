import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'data/services/image_migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Run migration for existing images (one-time)
  await ImageMigrationService.migrateExistingImages();

  runApp(const DietApp());
}
