/// LOCAL DEVELOPMENT ONLY. Test accounts created by
/// `kameti-backend/supabase/seed.sql` on the local Supabase. They never
/// exist in kameti-prod, and the buttons that use them only appear in the
/// dev flavor with a backend configured.
abstract final class DevAccounts {
  static const owner = 'owner@kameti.test';
  static const member = 'member@kameti.test';
  static const password = 'kameti-dev-pass';
}
