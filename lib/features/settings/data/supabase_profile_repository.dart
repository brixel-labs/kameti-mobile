import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/settings/domain/profile_models.dart';
import 'package:kameti/features/settings/domain/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const new(this._db);

  final SupabaseClient _db;

  @override
  Future<Result<Profile>> myProfile(String userId) => Result.guard(() async {
    final row = await _db.from('profiles').select().eq('id', userId).single();
    return Profile.fromJson(Map<String, dynamic>.from(row));
  });
}
