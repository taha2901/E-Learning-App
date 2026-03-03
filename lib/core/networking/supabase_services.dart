import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  //url , apikey
  static const String url = 'https://zhpohglsymdyclkoslba.supabase.co';
  static const String apiKey = 'sb_publishable_POk0lO3FGS1ctsneU9yx2Q_JYV3Iqa7';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: apiKey,
    );
  }
}
