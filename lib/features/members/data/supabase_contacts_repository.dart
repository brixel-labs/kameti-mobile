import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/members/domain/contact_models.dart';
import 'package:kameti/features/members/domain/contacts_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseContactsRepository implements ContactsRepository {
  const new(this._db);

  final SupabaseClient _db;

  @override
  Future<Result<List<Contact>>> listContacts() => Result.guard(() async {
    final rows = await _db.from('contacts').select().order('name');
    return [
      for (final r in rows) Contact.fromJson(Map<String, dynamic>.from(r)),
    ];
  });
}
