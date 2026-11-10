import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/settings/domain/profile_models.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's profile (RLS only returns their own row).
  Future<Result<Profile>> myProfile(String userId);
}
