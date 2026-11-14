package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import java.net.URLEncoder

/** The text and WhatsApp link for reminding someone who doesn't have the app (FR-84). */
object ReminderLogic {
    /**
     * [template] is the app's "Hi %1$s, a reminder that %2$s for %3$s is due
     * by the %4$s. Thank you!" string.
     */
    fun text(template: String, name: String, owed: Money, kameti: String, dueDay: Int): String =
        String.format(template, firstName(name), owed.format(), kameti, ordinal(dueDay))

    /** "0300 1234567" becomes wa.me/923001234567 with the message; no usable phone is `null` (use the share sheet). */
    fun whatsAppUrl(phone: String?, text: String): String? {
        if (phone == null) return null
        var digits = phone.filter { it.isDigit() }
        if (digits.startsWith("00")) digits = digits.drop(2)
        if (digits.startsWith("0")) digits = "92" + digits.drop(1)
        if (digits.length < 10) return null
        return "https://wa.me/$digits?text=" + URLEncoder.encode(text, "UTF-8").replace("+", "%20")
    }

    fun ordinal(day: Int): String {
        val suffix = if (day % 100 in 11..13) {
            "th"
        } else {
            when (day % 10) {
                1 -> "st"
                2 -> "nd"
                3 -> "rd"
                else -> "th"
            }
        }
        return "$day$suffix"
    }
}
