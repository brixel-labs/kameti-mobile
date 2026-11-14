package com.brixel.kameti.domain

import com.brixel.kameti.core.Timestamp
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * Row of `public.audit_log` (FR-90). The owner reads every entry of a kameti;
 * a joined member reads the entries about themselves (row-level security).
 */
@Serializable
data class AuditEntry(
    val id: Long,
    val kametiId: String,
    val action: String,
    val entity: String,
    val at: Timestamp,
    val memberId: String? = null,
    val actorId: String? = null,
    val entityId: String? = null,
    /**
     * The row before and after the change. Usually an object, but a few
     * actions store a list (a slot's shares), so any JSON is accepted.
     */
    val before: JsonElement? = null,
    val after: JsonElement? = null,
)

/** Row of `public.profiles`: the signed-in user's own profile. */
@Serializable
data class Profile(val id: String, val displayName: String, val avatarUrl: String? = null)

/**
 * Row of `public.contacts`: one person in the owner's private "My people"
 * list. Only the owner can read it; members never see it.
 */
@Serializable
data class Contact(
    val id: String,
    val ownerId: String,
    val name: String,
    val email: String? = null,
    val phone: String? = null,
    val note: String? = null,
)
