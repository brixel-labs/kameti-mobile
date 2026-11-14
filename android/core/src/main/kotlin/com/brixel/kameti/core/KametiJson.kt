package com.brixel.kameti.core

import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.format.DateTimeParseException
import java.time.temporal.ChronoUnit
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNamingStrategy
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.longOrNull

/** A calendar day or month from a Postgres `date` column (`YYYY-MM-DD`). */
typealias Day = @Serializable(DateOnlySerializer::class) LocalDate

/** A moment from a Postgres `timestamptz` column. */
typealias Timestamp = @Serializable(InstantSerializer::class) Instant

/**
 * How backend rows become Kotlin values: snake_case keys, `YYYY-MM-DD` dates
 * as [LocalDate] ([DateOnlySerializer]), and ISO-8601 timestamps with or
 * without fractional seconds as [Instant] ([InstantSerializer]; Postgres
 * sends both). Columns whose shape isn't fixed (audit `before` / `after`) use
 * `JsonElement`.
 */
object KametiJson {
    @OptIn(ExperimentalSerializationApi::class)
    val json: Json = Json {
        namingStrategy = JsonNamingStrategy.SnakeCase
        ignoreUnknownKeys = true
        explicitNulls = false
        coerceInputValues = true
    }
}

/** `YYYY-MM-DD` <-> [LocalDate]. */
object DateOnlySerializer : KSerializer<LocalDate> {
    override val descriptor = PrimitiveSerialDescriptor("DateOnly", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): LocalDate {
        val text = decoder.decodeString()
        return DateOnly.parse(text) ?: throw SerializationException("Unrecognised date: $text")
    }

    override fun serialize(encoder: Encoder, value: LocalDate) = encoder.encodeString(DateOnly.string(value))
}

/** ISO-8601 timestamp (any offset, fractional seconds or not) <-> [Instant]. */
object InstantSerializer : KSerializer<Instant> {
    override val descriptor = PrimitiveSerialDescriptor("Instant", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): Instant {
        val text = decoder.decodeString()
        return try {
            OffsetDateTime.parse(text).toInstant()
        } catch (_: DateTimeParseException) {
            throw SerializationException("Unrecognised timestamp: $text")
        }
    }

    /** Whole seconds, UTC: `2026-11-09T10:00:00Z`. */
    override fun serialize(encoder: Encoder, value: Instant) =
        encoder.encodeString(value.truncatedTo(ChronoUnit.SECONDS).toString())
}

// Reading free-form JSON (audit `before` / `after`): each accessor is `null`
// when the value has another shape.

/** A field of an object; `null` for anything else, a missing key or JSON null. */
operator fun JsonElement.get(key: String): JsonElement? =
    (this as? JsonObject)?.get(key)?.takeUnless { it is JsonNull }

val JsonElement.longValue: Long? get() = (this as? JsonPrimitive)?.takeUnless { it.isString }?.longOrNull
val JsonElement.stringValue: String? get() = (this as? JsonPrimitive)?.takeIf { it.isString }?.content
val JsonElement.boolValue: Boolean? get() = (this as? JsonPrimitive)?.takeUnless { it.isString }?.booleanOrNull
val JsonElement.arrayValue: List<JsonElement>? get() = this as? JsonArray
val JsonElement.objectValue: Map<String, JsonElement>? get() = this as? JsonObject
