import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  static const String _url = 'https://zhpohglsymdyclkoslba.supabase.co';
  static const String _apiKey = 'sb_publishable_POk0lO3FGS1ctsneU9yx2Q_JYV3Iqa7';

  /// Default timeout for all Supabase calls (can be overridden per call).
  static const Duration defaultTimeout = Duration(seconds: 15);

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _apiKey,
    );
  }

  /// Convenience getter for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}