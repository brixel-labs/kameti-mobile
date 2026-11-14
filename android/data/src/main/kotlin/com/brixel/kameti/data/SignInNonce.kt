package com.brixel.kameti.data

import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64

/**
 * The nonce pair an ID-token sign-in needs: the provider gets the SHA-256
 * hash, and Supabase gets the raw value to check the token against.
 * (`AppleNonce` on iOS; Android uses it for Google.)
 */
data class SignInNonce(val raw: String) {
    val hashed: String = sha256Hex(raw)

    companion object {
        /** 32 random bytes, URL-safe base64. */
        fun make(): SignInNonce {
            val bytes = ByteArray(32).also(SecureRandom()::nextBytes)
            return SignInNonce(Base64.getUrlEncoder().withoutPadding().encodeToString(bytes))
        }

        internal fun sha256Hex(text: String): String =
            MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
                .joinToString("") { "%02x".format(it) }
    }
}
