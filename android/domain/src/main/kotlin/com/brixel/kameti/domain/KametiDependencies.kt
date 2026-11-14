package com.brixel.kameti.domain

import com.brixel.kameti.core.KametiClock
import java.util.UUID

/**
 * Everything a screen may depend on, as interfaces. The app module builds the
 * real one (Supabase); tests and the demo flavor build one from fakes.
 */
data class KametiDependencies(
    val kametis: KametiRepository,
    val ledger: LedgerRepository,
    val payments: PaymentsRepository,
    val invites: InvitesRepository,
    val audit: AuditRepository,
    val profiles: ProfileRepository,
    val contacts: ContactsRepository,
    val auth: AuthRepository,
    val notes: NotesRepository = UnavailableNotesRepository(),
    val account: AccountRepository = UnavailableAccountRepository(),
    val notifications: NotificationsRepository = UnavailableNotificationsRepository(),
    val live: LiveUpdatesRepository = UnavailableLiveUpdates(),
    val clock: KametiClock = KametiClock(),
    /** What Profile keeps on the phone; the app backs it with SharedPreferences. */
    val profileCache: ProfileCache = ProfileCache(clock = clock),
    /**
     * One key per user action, reused on retry, so a double tap never
     * records a payment twice.
     */
    val makeIdempotencyKey: () -> String = { UUID.randomUUID().toString() },
)
