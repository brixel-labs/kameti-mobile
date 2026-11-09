import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/app/app.dart';
import 'package:kameti/core/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared start-up for every flavor's `main_*.dart`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.hasBackend) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  } else {
    debugPrint(
      'Kameti: no SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY given; running '
      'without a backend. Pass --dart-define-from-file=env/dev.json.',
    );
  }

  runApp(const ProviderScope(child: KametiApp()));
}
