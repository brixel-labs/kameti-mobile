package com.brixel.kameti.data

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.stringValue
import io.github.jan.supabase.auth.exception.AuthRestException
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.postgrest.exception.PostgrestRestException
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/**
 * Turns anything supabase-kt or the network throws into a [Failure]
 * (REQUIREMENTS: repositories never leak raw errors into the UI).
 */
internal fun Throwable.toFailure(): Failure = when (this) {
    is Failure -> this
    // Kameti RPCs raise `message = <stable key>, details = <english text>`.
    is PostgrestRestException -> Failure.Server(error, details?.stringValue)
    is AuthRestException -> Failure.Auth(errorDescription)
    is RestException -> Failure.Server("http_$statusCode", error)
    // No connection, DNS, a dropped socket or a timeout (Ktor's timeout and
    // supabase-kt's HttpRequestException are both IOExceptions).
    is IOException -> Failure.Network
    else -> Failure.Unknown(toString())
}

/**
 * Runs [body] and rethrows anything it throws as a [Failure]. Cancellation
 * passes through untouched.
 */
internal inline fun <T> call(body: () -> T): T =
    try {
        body()
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (error: Exception) {
        throw error.toFailure()
    }
