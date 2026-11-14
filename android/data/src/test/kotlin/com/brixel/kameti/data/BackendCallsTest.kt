package com.brixel.kameti.data

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.SignInProblem
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.ShareInput
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.serializer.KotlinXSerializer
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.toByteArray
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import java.io.IOException
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonElement

/** A Supabase client whose requests are answered by [handler] instead of a server. */
private fun client(handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData): SupabaseClient =
    createSupabaseClient("https://example.supabase.co", "test-key") {
        httpEngine = MockEngine { handler(it) }
        defaultSerializer = KotlinXSerializer(KametiJson.json)
        install(Postgrest)
        install(Functions)
    }

private fun MockRequestHandleScope.json(body: String, status: HttpStatusCode = HttpStatusCode.OK) =
    respond(body, status, headersOf(HttpHeaders.ContentType, "application/json"))

private const val KAMETI_ROW = """{"id":"k1","owner_id":"u1","name":"Office Kameti","start_month":"2026-10-01",
    "months_n":20,"slot_amount_c":250000,"due_day":10,"reminder_days":[1,5,8,10],"max_slots_per_member":4,
    "status":"active","started_at":"2026-10-01T05:00:00.123456+00:00","created_at":"2026-09-20T10:00:00+00:00"}"""

class BackendCallsTest {
    @Test
    fun readsARowsListFromTheTable() = runTest {
        var asked: HttpRequestData? = null
        val repository = SupabaseKametiRepository(client { asked = it; json("[$KAMETI_ROW]") })

        val kametis = repository.listKametis()

        assertEquals(HttpMethod.Get, asked?.method)
        assertEquals("/rest/v1/kametis", asked?.url?.encodedPath)
        assertEquals("created_at.desc.nullslast", asked?.url?.parameters?.get("order"))
        assertEquals(1, kametis.size)
        assertEquals(Money(250_000), kametis[0].slotAmountC)
        assertEquals(DateOnly.make(2026, 10), kametis[0].startMonth)
        assertEquals(KametiStatus.Active, kametis[0].status)
    }

    @Test
    fun aWriteIsAnRpcWithTheBackendsParameterNames() = runTest {
        var asked: HttpRequestData? = null
        var sent = ""
        val repository = SupabaseKametiRepository(
            client {
                asked = it
                sent = it.body.toByteArray().decodeToString()
                json(KAMETI_ROW)
            },
        )
        val new = NewKameti(name = "Office Kameti", startMonth = DateOnly.make(2026, 10), months = 20, slotAmount = Money(250_000))

        val created = repository.createKameti(new)

        assertEquals(HttpMethod.Post, asked?.method)
        assertEquals("/rest/v1/rpc/create_kameti", asked?.url?.encodedPath)
        assertEquals(Params.createKameti(new), KametiJson.json.decodeFromString<JsonElement>(sent))
        assertEquals("k1", created.id)
    }

    @Test
    fun aMissingEmailServiceIsNotAnError() = runTest {
        val invites = SupabaseInvitesRepository(client { respond("email_not_configured", HttpStatusCode.ServiceUnavailable) })
        val link = KametiJson.json.decodeFromString<com.brixel.kameti.domain.InviteLink>(
            """{"invite_id":"i1","member_id":"m1","token":"t","code":"K7Q2MX","link":"https://x","expires_at":"2026-12-01T00:00:00Z"}""",
        )
        assertEquals(false, invites.sendInviteEmail(link))
    }

    @Test
    fun deleteAccountReportsTheFunctionsErrorCode() = runTest {
        val account = SupabaseAccountRepository(
            client { json("""{"error":"owner_has_active_kametis"}""", HttpStatusCode.Conflict) },
        )
        val failure = assertFailsWith<Failure> { account.deleteAccount() }
        assertEquals(Failure.Server("owner_has_active_kametis"), failure)
    }
}

class FailureMappingTest {
    @Test
    fun rpcErrorKeepsItsStableKey() = runTest {
        val repository = SupabaseKametiRepository(
            client {
                json(
                    """{"code":"22023","details":"Shares add up to 200000, not 250000.","hint":null,
                        "message":"shares_must_sum_to_slot_amount"}""",
                    HttpStatusCode.BadRequest,
                )
            },
        )
        val failure = assertFailsWith<Failure> {
            repository.setSlotShares("s1", listOf(ShareInput("m1", Money(200_000))))
        }
        assertEquals(
            Failure.Server("shares_must_sum_to_slot_amount", "Shares add up to 200000, not 250000."),
            failure,
        )
    }

    @Test
    fun networkErrorsBecomeNetwork() = runTest {
        for (error in listOf(UnknownHostException("x"), SocketTimeoutException(), ConnectException(), IOException("reset"))) {
            assertEquals(Failure.Network, error.toFailure())
        }
        assertIs<Failure.Unknown>(IllegalArgumentException("a bad URL is not a network outage").toFailure())

        // The same through a real call: the engine can't reach the server.
        val repository = SupabaseKametiRepository(client { throw UnknownHostException("example.supabase.co") })
        assertEquals(Failure.Network, assertFailsWith<Failure> { repository.startKameti("k1") })
    }

    @Test
    fun failuresPassThroughUntouched() {
        assertEquals(Failure.Auth("x"), Failure.Auth("x").toFailure())
    }

    @Test
    fun signInErrorsExplainThemselves() {
        // A refused token is a sign-in problem, not "your session ended".
        val refused = SupabaseAuthRepository.signInFailure(Failure.Auth("Unacceptable audience in id_token"))
        assertEquals(Failure.SignIn(SignInProblem.Rejected, "Unacceptable audience in id_token"), refused)
        val odd = SupabaseAuthRepository.signInFailure(IllegalStateException("boom"))
        assertTrue(odd is Failure.SignIn && odd.problem == SignInProblem.Rejected)
        assertEquals(Failure.Network, SupabaseAuthRepository.signInFailure(UnknownHostException("x")))
    }
}
