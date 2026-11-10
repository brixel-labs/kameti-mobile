import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/members/data/supabase_contacts_repository.dart';
import 'package:kameti/features/members/domain/contact_models.dart';
import 'package:kameti/features/members/domain/contacts_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contacts_providers.g.dart';

@Riverpod(keepAlive: true)
ContactsRepository contactsRepository(Ref ref) =>
    SupabaseContactsRepository(ref.watch(supabaseClientProvider));

/// The owner's contacts, by name. Invalidate after adding or editing a
/// member, which can create or change a contact.
@riverpod
Future<List<Contact>> myContacts(Ref ref) async =>
    (await ref.watch(contactsRepositoryProvider).listContacts()).getOrThrow();
