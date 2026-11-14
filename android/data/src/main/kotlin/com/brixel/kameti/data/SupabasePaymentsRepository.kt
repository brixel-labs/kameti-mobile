package com.brixel.kameti.data

import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.PaymentsRepository
import com.brixel.kameti.domain.Payout
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import java.time.LocalDate

internal class SupabasePaymentsRepository(private val client: SupabaseClient) : PaymentsRepository {
    override suspend fun payments(kametiId: String): List<Payment> = call {
        client.from("payments").select {
            filter { eq("kameti_id", kametiId) }
            order("received_on", Order.DESCENDING)
            order("created_at", Order.DESCENDING)
        }.decodeList()
    }

    override suspend fun payouts(kametiId: String): List<Payout> = call {
        client.from("payouts").select {
            filter { eq("kameti_id", kametiId) }
            order("paid_on", Order.DESCENDING)
        }.decodeList()
    }

    override suspend fun recordPayment(new: NewPayment): Payment = call {
        client.postgrest.rpc("record_payment", Params.recordPayment(new)).decodeAs()
    }

    override suspend fun recordPayments(
        kametiId: String,
        receivedOn: LocalDate,
        items: List<BatchPaymentItem>,
        method: PaymentMethod,
    ): List<Payment> = call {
        client.postgrest.rpc(
            "record_payments_batch",
            Params.recordPayments(kametiId, receivedOn, items, method),
        ).decodeList()
    }

    override suspend fun voidPayment(id: String, reason: String): Payment = call {
        client.postgrest.rpc("void_payment", params("p_payment_id" to text(id), "p_reason" to text(reason))).decodeAs()
    }

    override suspend fun recordPayout(new: NewPayout): Payout = call {
        client.postgrest.rpc("record_payout", Params.recordPayout(new)).decodeAs()
    }

    override suspend fun voidPayout(id: String, reason: String): Payout = call {
        client.postgrest.rpc("void_payout", params("p_payout_id" to text(id), "p_reason" to text(reason))).decodeAs()
    }
}
