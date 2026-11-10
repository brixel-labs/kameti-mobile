import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_models.freezed.dart';
part 'contact_models.g.dart';

/// Row of `public.contacts`: one person in the owner's private "My people"
/// list (§5.3). Only the owner can read it; members never see it.
@freezed
abstract class Contact with _$Contact {
  const factory({
    required String id,
    required String ownerId,
    required String name,
    String? email,
    String? phone,
    String? note,
  }) = _Contact;

  factory fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
}
