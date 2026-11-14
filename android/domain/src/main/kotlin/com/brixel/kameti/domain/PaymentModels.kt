package com.brixel.kameti.domain

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.Timestamp
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class PaymentMethod {
    @SerialName("cash") Cash,
    @SerialName("bank_transfer") BankTransfer,
    @SerialName("other") Other,
}

/** Row of `public.payments`. Append-only: corrections are voids. */
@Serializable
data class Payment(
    val id: String,
    val kametiId: String,
    val memberId: String,
    val amount: Money,
    val receivedOn: Day,
    val method: PaymentMethod,
    val createdAt: Timestamp,
    val reference: String? = null,
    val note: String? = null,
    val paidByName: String? = null,
    val voidedAt: Timestamp? = null,
    val voidReason: String? = null,
) {
    val isVoided: Boolean get() = voidedAt != null
}

/** Row of `public.payouts`. */
@Serializable
data class Payout(
    val id: String,
    val kametiId: String,
    val slotId: String,
    val memberId: String,
    val amount: Money,
    val paidOn: Day,
    val method: PaymentMethod,
    val reference: String? = null,
    val note: String? = null,
    val voidedAt: Timestamp? = null,
    val voidReason: String? = null,
) {
    val isVoided: Boolean get() = voidedAt != null
}

/**
 * Input for `record_payment`. [idempotencyKey] is one per user action and is
 * reused on retry, so a double tap never records twice.
 */
data class NewPayment(
    val memberId: String,
    val amount: Money,
    val receivedOn: Day,
    val idempotencyKey: String,
    val method: PaymentMethod = PaymentMethod.Cash,
    val reference: String? = null,
    val note: String? = null,
    val paidByName: String? = null,
)

/** One line of a tap-to-settle batch (`record_payments_batch`). */
data class BatchPaymentItem(
    val memberId: String,
    val amount: Money,
    val idempotencyKey: String,
    val paidByName: String? = null,
    val reference: String? = null,
    val note: String? = null,
)

/** Input for `record_payout`. */
data class NewPayout(
    val slotId: String,
    val memberId: String,
    val amount: Money,
    val paidOn: Day,
    val idempotencyKey: String,
    val method: PaymentMethod = PaymentMethod.Cash,
    val reference: String? = null,
    val note: String? = null,
)
