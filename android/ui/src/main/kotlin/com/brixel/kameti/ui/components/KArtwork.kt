package com.brixel.kameti.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp

/**
 * The first-time Home picture: a dashed circle, three people-dots and a green
 * tile with a plus (board AF · Home first time).
 */
@Composable
fun KEmptyIllustration(modifier: Modifier = Modifier) {
    val brand = KColors.brand
    val subtle = KColors.brandSubtle
    val onBrand = KColors.textOnBrand
    Canvas(modifier.size(width = 120.dp, height = 96.dp).clearAndSetSemantics {}) {
        val scale = minOf(size.width / 120f, size.height / 96f)
        fun point(x: Float, y: Float) =
            Offset((size.width - 120 * scale) / 2 + x * scale, (size.height - 96 * scale) / 2 + y * scale)
        drawCircle(
            subtle, radius = 32 * scale, center = point(60f, 48f),
            style = Stroke(3 * scale, pathEffect = PathEffect.dashPathEffect(floatArrayOf(6 * scale, 6 * scale))),
        )
        for ((x, y) in listOf(60f to 16f, 88f to 62f, 32f to 62f)) {
            drawCircle(subtle, radius = 9 * scale, center = point(x, y))
            drawCircle(brand, radius = 9 * scale, center = point(x, y), style = Stroke(2 * scale))
        }
        drawRoundRect(brand, topLeft = point(48f, 38f), size = Size(24 * scale, 20 * scale), cornerRadius = CornerRadius(5 * scale))
        drawLine(onBrand, point(54f, 48f), point(66f, 48f), strokeWidth = 2.4f * scale, cap = StrokeCap.Round)
        drawLine(onBrand, point(60f, 42f), point(60f, 54f), strokeWidth = 2.4f * scale, cap = StrokeCap.Round)
    }
}

/**
 * Google's multicolour "G" for the Continue with Google button. It is
 * Google's brand artwork, so its colours are not themed.
 */
@Composable
fun KGoogleLogo(modifier: Modifier = Modifier) {
    Image(painterResource(R.drawable.k_google_g), contentDescription = null, modifier = modifier.size(20.dp))
}
