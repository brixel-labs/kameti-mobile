package com.brixel.kameti.testsupport

import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.ContactsRepository

/**
 * The owner's people, shared by the contacts and kameti repositories so a
 * person added or edited in a kameti shows up in "From my people" too.
 */
class SampleContactStore {
    private val lock = Any()
    private var rows = SampleData.contacts
    private var counter = 0

    val all: List<Contact> get() = synchronized(lock) { rows }

    fun contact(id: String?): Contact? = id?.let { wanted -> synchronized(lock) { rows.firstOrNull { it.id == wanted } } }

    /** Like `add_member`: an email already in the list reuses that person. */
    fun findOrCreate(name: String, email: String?, phone: String?): Contact = synchronized(lock) {
        if (email != null) rows.firstOrNull { it.email?.lowercase() == email }?.let { return it }
        counter += 1
        val created = Contact("c-new-$counter", SampleData.USER_ID, name, email, phone)
        rows = rows + created
        created
    }

    /** Like `update_member`: `null` keeps a field, an empty string clears it. */
    fun update(id: String?, name: String, email: String?, phone: String?): Contact = synchronized(lock) {
        val old = rows.firstOrNull { it.id == id }
        if (old == null) counter += 1
        val updated = Contact(
            id = old?.id ?: "c-new-$counter", ownerId = SampleData.USER_ID, name = old?.name ?: name,
            email = if (email != null) email.ifEmpty { null } else old?.email,
            phone = if (phone != null) phone.ifEmpty { null } else old?.phone,
            note = old?.note,
        )
        rows = if (old != null) rows.map { if (it.id == old.id) updated else it } else rows + updated
        updated
    }
}

class SampleContactsRepository(private val store: SampleContactStore) : ContactsRepository {
    override suspend fun contacts(): List<Contact> = store.all
}
