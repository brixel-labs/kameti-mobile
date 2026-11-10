import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// Row of `public.profiles`: the signed-in user's own profile.
@freezed
abstract class Profile with _$Profile {
  const factory({
    required String id,
    required String displayName,
    String? avatarUrl,
  }) = _Profile;

  factory fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
