package com.brixel.kameti.ui

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Chat
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.ReceiptLong
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.automirrored.outlined.StickyNote2
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.automirrored.rounded.Send
import androidx.compose.material.icons.automirrored.rounded.Undo
import androidx.compose.material.icons.outlined.AccountBalance
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Contrast
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.EditNote
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.HighlightOff
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.HourglassEmpty
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.MailOutline
import androidx.compose.material.icons.outlined.ManageAccounts
import androidx.compose.material.icons.outlined.NoAccounts
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonAddAlt
import androidx.compose.material.icons.outlined.PersonOff
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.Verified
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material.icons.outlined.WifiOff
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.AddCircle
import androidx.compose.material.icons.rounded.Archive
import androidx.compose.material.icons.rounded.ArrowDownward
import androidx.compose.material.icons.rounded.ArrowUpward
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ChevronLeft
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.Group
import androidx.compose.material.icons.rounded.Groups
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.KeyboardArrowDown
import androidx.compose.material.icons.rounded.KeyboardArrowUp
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.NorthEast
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Remove
import androidx.compose.material.icons.rounded.Report
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Shuffle
import androidx.compose.material.icons.rounded.SwapHoriz
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Every icon the app uses, named for its job. Each one stands in for the SF
 * Symbol the iOS app uses in the same place (in the comment), so the two apps
 * stay in step. Feature code never reaches for an icon library directly.
 */
object KIcons {
    val check = Icons.Rounded.Check // checkmark
    val plus = Icons.Rounded.Add // plus
    val minus = Icons.Rounded.Remove // minus
    val close = Icons.Rounded.Close // xmark
    val chevronRight = Icons.Rounded.ChevronRight // chevron.right
    val chevronLeft = Icons.Rounded.ChevronLeft // chevron.left
    val chevronDown = Icons.Rounded.KeyboardArrowDown // chevron.down
    val chevronUp = Icons.Rounded.KeyboardArrowUp // chevron.up
    val arrowUp = Icons.Rounded.ArrowUpward // arrow.up
    val arrowDown = Icons.Rounded.ArrowDownward // arrow.down
    val arrowRight = Icons.AutoMirrored.Rounded.ArrowForward // arrow.right
    val arrowUpRight = Icons.Rounded.NorthEast // arrow.up.right
    val swap = Icons.Rounded.SwapHoriz // arrow.left.arrow.right
    val refresh = Icons.Rounded.Refresh // arrow.clockwise
    val undo = Icons.AutoMirrored.Rounded.Undo // arrow.uturn.backward
    val more = Icons.Rounded.MoreHoriz // ellipsis
    val search = Icons.Rounded.Search // magnifyingglass
    val share = Icons.Rounded.Share // square.and.arrow.up
    val shuffle = Icons.Rounded.Shuffle // shuffle

    val warning = Icons.Outlined.WarningAmber // exclamationmark.triangle
    val warningFilled = Icons.Rounded.Warning // exclamationmark.triangle.fill
    val error = Icons.Outlined.ErrorOutline // exclamationmark.circle
    val errorFilled = Icons.Rounded.Error // exclamationmark.circle.fill
    val stopFilled = Icons.Rounded.Report // xmark.octagon.fill
    val info = Icons.Outlined.Info // info.circle
    val infoFilled = Icons.Rounded.Info // info.circle.fill
    val checkCircle = Icons.Outlined.CheckCircle // checkmark.circle
    val checkCircleFilled = Icons.Rounded.CheckCircle // checkmark.circle.fill
    val closeCircle = Icons.Outlined.HighlightOff // xmark.circle
    val plusCircle = Icons.Outlined.AddCircleOutline // plus.circle
    val plusCircleFilled = Icons.Rounded.AddCircle // plus.circle.fill
    val circle = Icons.Outlined.RadioButtonUnchecked // circle
    val circleHalf = Icons.Outlined.Contrast // circle.lefthalf.filled
    val verified = Icons.Outlined.Verified // checkmark.seal
    val help = Icons.AutoMirrored.Outlined.HelpOutline // questionmark.circle

    val person = Icons.Outlined.Person // person
    val personFilled = Icons.Rounded.Person // person.fill
    val people = Icons.Outlined.Group // person.2
    val peopleFilled = Icons.Rounded.Group // person.2.fill
    val peopleThreeFilled = Icons.Rounded.Groups // person.3.fill
    val personAdd = Icons.Outlined.PersonAddAlt // person.badge.plus
    val personWaiting = Icons.Outlined.ManageAccounts // person.badge.clock
    val personOff = Icons.Outlined.PersonOff // person.slash
    val personProblem = Icons.Outlined.NoAccounts // person.crop.circle.badge.exclamationmark

    val clock = Icons.Outlined.Schedule // clock
    val history = Icons.Outlined.History // clock.arrow.circlepath
    val hourglass = Icons.Outlined.HourglassEmpty // hourglass
    val calendar = Icons.Outlined.CalendarMonth // calendar
    val bell = Icons.Outlined.Notifications // bell
    val bellOff = Icons.Outlined.NotificationsOff // bell.slash
    val envelope = Icons.Outlined.MailOutline // envelope
    val message = Icons.AutoMirrored.Outlined.Chat // message.fill
    val send = Icons.AutoMirrored.Outlined.Send // paperplane
    val sendFilled = Icons.AutoMirrored.Rounded.Send // paperplane.fill
    val inbox = Icons.Outlined.Inbox // tray
    val home = Icons.Outlined.Home // house

    val edit = Icons.Outlined.Edit // pencil
    val editSetup = Icons.Outlined.EditNote // pencil.and.list.clipboard
    val note = Icons.AutoMirrored.Outlined.StickyNote2 // note.text
    val checklist = Icons.Outlined.Checklist // checklist
    val trash = Icons.Outlined.Delete // trash
    val trashFilled = Icons.Rounded.Delete // trash.fill
    val archive = Icons.Outlined.Archive // archivebox
    val archiveFilled = Icons.Rounded.Archive // archivebox.fill
    val duplicate = Icons.Outlined.ContentCopy // plus.square.on.square
    val lock = Icons.Outlined.Lock // lock
    val lockFilled = Icons.Rounded.Lock // lock.fill
    val key = Icons.Outlined.Key // key
    val shield = Icons.Outlined.Shield // shield
    val eye = Icons.Outlined.Visibility // eye
    val signOut = Icons.AutoMirrored.Outlined.Logout // rectangle.portrait.and.arrow.right

    val bank = Icons.Outlined.AccountBalance // building.columns
    val cash = Icons.Outlined.Payments // banknote
    val receipt = Icons.AutoMirrored.Outlined.ReceiptLong // receipt
    val moon = Icons.Outlined.DarkMode // moon
    val appIcon = Icons.Outlined.Apps // app
    val offline = Icons.Outlined.WifiOff // wifi.slash
    val cloudProblem = Icons.Outlined.CloudOff // exclamationmark.icloud
}

/**
 * An icon from [KIcons]. Decorative by default; pass [label] for an icon that
 * stands alone, so screen readers can name it.
 */
@Composable
fun KIcon(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    tint: Color = KColors.textSecondary,
    size: Dp = 20.dp,
    label: String? = null,
) {
    Icon(imageVector = icon, contentDescription = label, modifier = modifier.size(size), tint = tint)
}
