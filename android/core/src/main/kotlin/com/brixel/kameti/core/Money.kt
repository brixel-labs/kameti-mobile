package com.brixel.kameti.core

import kotlinx.serialization.Serializable

/**
 * An amount of Pakistani rupees. Always whole rupees (no paisa).
 *
 * Never use `Double` for money in this app. Every amount on screen goes
 * through `Money` and its formatting (`format()` / `KMoneyText`).
 *
 * Serialises as a bare integer, like Postgres `bigint`.
 */
@Serializable
@JvmInline
value class Money(val rupees: Long) : Comparable<Money> {
    val isZero: Boolean get() = rupees == 0L
    val isNegative: Boolean get() = rupees < 0
    val isPositive: Boolean get() = rupees > 0

    operator fun plus(other: Money) = Money(rupees + other.rupees)
    operator fun minus(other: Money) = Money(rupees - other.rupees)
    operator fun times(count: Int) = Money(rupees * count)
    operator fun unaryMinus() = Money(-rupees)
    override fun compareTo(other: Money): Int = rupees.compareTo(other.rupees)

    fun abs() = Money(kotlin.math.abs(rupees))

    /**
     * Whether this is a multiple of the positive [step] (for example the
     * Rs 1,000 steps a slot share must use).
     */
    fun isMultipleOf(step: Money): Boolean = step.rupees > 0 && rupees % step.rupees == 0L

    /** Lakh/crore grouping: `Rs 24,00,000`. Without the symbol: `24,00,000`. */
    fun format(symbol: Boolean = true): String {
        val grouped = groupIndian(kotlin.math.abs(rupees))
        val sign = if (rupees < 0) MINUS else ""
        return if (symbol) "${sign}Rs $grouped" else "$sign$grouped"
    }

    /** Compact form for tight spaces: `50K`, `1.25 L`, `2.4 Cr`. */
    fun formatCompact(): String {
        val n = kotlin.math.abs(rupees)
        val sign = if (rupees < 0) MINUS else ""
        return when {
            n >= 10_000_000 -> "$sign${trimmed(n, 10_000_000)} Cr"
            n >= 100_000 -> "$sign${trimmed(n, 100_000)} L"
            n >= 1_000 -> "$sign${trimmed(n, 1_000)}K"
            else -> "$sign$n"
        }
    }

    override fun toString(): String = format()

    companion object {
        val ZERO = Money(0)
        private const val MINUS = "−"

        /**
         * Parses user input such as `"2,50,000"` or `"250000"`. Returns `null`
         * for empty text or anything that isn't a whole number.
         */
        fun parse(input: String): Money? {
            val digits = input.replace(",", "").replace(" ", "")
            if (digits.isEmpty()) return null
            return digits.toLongOrNull()?.let(::Money)
        }

        /**
         * `n / divisor` to at most two decimals without trailing zeros, using
         * integer arithmetic only (round half up).
         */
        private fun trimmed(n: Long, divisor: Long): String {
            val hundredths = (n * 100 + divisor / 2) / divisor
            val whole = hundredths / 100
            val fraction = hundredths % 100
            if (fraction == 0L) return "$whole"
            val digits = (if (fraction < 10) "0$fraction" else "$fraction").removeSuffix("0")
            return "$whole.$digits"
        }

        private fun groupIndian(value: Long): String {
            val digits = value.toString()
            if (digits.length <= 3) return digits
            val last3 = digits.takeLast(3)
            var rest = digits.dropLast(3)
            val parts = ArrayDeque<String>()
            while (rest.length > 2) {
                parts.addFirst(rest.takeLast(2))
                rest = rest.dropLast(2)
            }
            if (rest.isNotEmpty()) parts.addFirst(rest)
            return parts.joinToString(",") + "," + last3
        }
    }
}
