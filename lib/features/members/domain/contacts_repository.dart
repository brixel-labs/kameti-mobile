import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/members/domain/contact_models.dart';

/// The owner's private contact list. Reads only: contacts are created and
/// changed through `add_member` / `update_member`.
abstract interface class ContactsRepository {
  Future<Result<List<Contact>>> listContacts();
}
