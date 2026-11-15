package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Member
import java.time.LocalDate

/**
 * How far the owner is with getting people onto the app: who is still to join, so the Overview can
 * say so. Members the owner marked as not using the app, and the owner's own row, don't count.
 */
internal data class SetupProgress(
    /** Everyone expected on the app: all members except the owner's own row and the guests. */
    val expected: Int,
    /** Not joined yet: not invited, invited, or waiting for the owner's approval. */
    val waiting: List<Member>,
) {
    val isComplete: Boolean get() = waiting.isEmpty()

    /** Someone is waiting for the owner to approve them. */
    val needsApproval: Boolean get() = waiting.any { it.joinStatus == JoinStatus.PendingApproval }

    companion object {
        fun of(data: KametiDetailData): SetupProgress {
            var expected = 0
            val waiting = mutableListOf<Member>()
            for (member in data.members) {
                when (AccessState.of(member, data)) {
                    AccessState.Owner, is AccessState.Guest -> Unit
                    AccessState.Joined -> expected += 1
                    is AccessState.NeedsApproval, is AccessState.Invited, is AccessState.NotInvited -> {
                        expected += 1
                        waiting += member
                    }
                }
            }
            return SetupProgress(expected, waiting)
        }
    }
}

/** A payment the owner just recorded for a member who isn't on the app, to offer a receipt for. */
internal data class PendingReceipt(val memberId: String, val amount: Money, val on: LocalDate)

/**
 * The short text for a member who isn't on the app (their own figures only, nobody else's): a
 * receipt right after a payment, or the owner's "Send update". Sent by WhatsApp or the share sheet.
 */
internal object GuestUpdate {
    fun text(
        strings: Strings, member: Member, data: KametiDetailData, receipt: PendingReceipt? = null, viewLink: String? = null,
    ): String {
        val first = firstName(member.name)
        val kameti = data.kameti.name
        val lines = mutableListOf<String>()
        if (receipt != null) {
            lines += strings.get(
                R.string.detail_hi_s_we_received_s_from_you_on, first, receipt.amount.format(), DetailLogic.dayMonth(receipt.on), kameti,
            )
        } else {
            val month = data.current?.let { DetailLogic.monthName(it.monthStart) }.orEmpty()
            lines += strings.get(R.string.detail_hi_s_heres_your_s_update_for_s, first, kameti, month)
        }
        PaymentLogic.monthRow(member.id, data)?.takeIf { it.due.isPositive }?.let { row ->
            lines += strings.get(R.string.detail_this_month_paid_s_of_s, row.allocated.format(), row.due.format())
        }
        data.balances.firstOrNull { it.memberId == member.id }?.let { balance ->
            lines += when {
                balance.owes.isPositive ->
                    strings.get(R.string.detail_you_owe_s_so_far_due_by_the, balance.owes.format(), ReminderLogic.ordinal(data.kameti.dueDay))
                balance.credit.isPositive -> strings.get(R.string.detail_youre_ahead_by_s, balance.credit.format())
                else -> strings.get(R.string.detail_youre_all_paid_up)
            }
        }
        DetailLogic.nextTurn(member, data.kameti, data.current?.monthIndex ?: 1, data.slots, data.shares)?.let { turn ->
            val month = DetailLogic.monthTitle(DetailLogic.monthStart(data.kameti, turn.monthIndex))
            lines += strings.get(R.string.detail_your_payout_is_in_s_s, month, turn.payout.format())
        }
        if (viewLink != null) lines += strings.get(R.string.detail_see_everything_any_time_s, viewLink)
        return lines.joinToString("\n")
    }
}
