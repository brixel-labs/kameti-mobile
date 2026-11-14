package com.brixel.kameti.navigation

import java.net.URI
import java.net.URISyntaxException

/**
 * Turns an opened URL into a route. Only invite links exist today:
 * - `https://kameti.fhbtechservices.com/join/<token>` (Kameti's own site, current);
 * - `https://www.fhbtechservices.com/kameti/join/<token>` (the first links sent,
 *   which still work and redirect to the new site).
 */
object DeepLink {
    const val SITE_HOST = "kameti.fhbtechservices.com"
    val LEGACY_HOSTS = setOf("www.fhbtechservices.com", "fhbtechservices.com")

    fun route(url: String): Route? {
        val uri = try {
            URI(url)
        } catch (_: URISyntaxException) {
            return null
        }
        if (uri.scheme != "https") return null
        val host = uri.host?.lowercase() ?: return null
        val parts = (uri.path ?: "").split("/").filter { it.isNotEmpty() }
        val token = when {
            host == SITE_HOST && parts.size == 2 && parts[0] == "join" -> parts[1]
            host in LEGACY_HOSTS && parts.size == 3 && parts[0] == "kameti" && parts[1] == "join" -> parts[2]
            else -> null
        }
        return token?.takeIf { it.isNotEmpty() }?.let { Route.Join(it) }
    }
}
