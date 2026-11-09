/// Build-time configuration, passed with
/// `--dart-define-from-file=env/<flavor>.json`.
///
/// Only public values belong here (the Supabase publishable key is public by
/// design). Never put the service-role key or any other secret in the app.
enum Flavor { dev, staging, prod }

class Env {
  const new _();

  static const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const inviteBaseUrl = String.fromEnvironment(
    'INVITE_BASE_URL',
    defaultValue: 'https://www.fhbtechservices.com/kameti/join',
  );

  static Flavor get flavor => Flavor.values.firstWhere(
    (f) => f.name == _flavor,
    orElse: () => Flavor.dev,
  );

  /// True when Supabase values were provided at build time.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
