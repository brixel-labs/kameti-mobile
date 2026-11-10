// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactsRepository)
final contactsRepositoryProvider = ContactsRepositoryProvider._();

final class ContactsRepositoryProvider
    extends
        $FunctionalProvider<
          ContactsRepository,
          ContactsRepository,
          ContactsRepository
        >
    with $Provider<ContactsRepository> {
  ContactsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContactsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContactsRepository create(Ref ref) {
    return contactsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsRepository>(value),
    );
  }
}

String _$contactsRepositoryHash() =>
    r'da63ea8f5b7f3900e94808ff8ba3806a4f33cbc9';

/// The owner's contacts, by name. Invalidate after adding or editing a
/// member, which can create or change a contact.

@ProviderFor(myContacts)
final myContactsProvider = MyContactsProvider._();

/// The owner's contacts, by name. Invalidate after adding or editing a
/// member, which can create or change a contact.

final class MyContactsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Contact>>,
          List<Contact>,
          FutureOr<List<Contact>>
        >
    with $FutureModifier<List<Contact>>, $FutureProvider<List<Contact>> {
  /// The owner's contacts, by name. Invalidate after adding or editing a
  /// member, which can create or change a contact.
  MyContactsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myContactsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myContactsHash();

  @$internal
  @override
  $FutureProviderElement<List<Contact>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Contact>> create(Ref ref) {
    return myContacts(ref);
  }
}

String _$myContactsHash() => r'7ce7081b768280cea33a5db203df3e531141c096';
