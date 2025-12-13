// lib/core/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://eghexqhdnbirdfgvgiua.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaGV4cWhkbmJpcmRmZ3ZnaXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTA5NTcsImV4cCI6MjA3ODU2Njk1N30.V92vL5vr1MTDb0_Oh141Lze0MuV4lF29R0AAv6ba5D8',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
