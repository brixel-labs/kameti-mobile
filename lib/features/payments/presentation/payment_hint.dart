import 'package:kameti/core/money/money.dart';

/// What a payment of some amount does to a member's balance, for the live
/// hint under the record-payment form (FR-41).
sealed class PaymentHint {
  const new();

  /// [owes] is what the member owes through the current month (zero when
  /// in credit); [leftForKameti] is everything still due for the whole
  /// kameti (E17).
  static PaymentHint? of({
    required Money? amount,
    required Money owes,
    required Money leftForKameti,
  }) {
    if (amount == null || !amount.isPositive) return null;
    if (amount > leftForKameti) return HintOverKameti(leftForKameti);
    if (amount < owes) return HintOwing(owes - amount);
    if (amount == owes) return const HintFullyPaid();
    return HintCredit(amount - owes);
  }
}

final class HintFullyPaid extends PaymentHint {
  const new();
}

final class HintOwing extends PaymentHint {
  const new(this.rest);
  final Money rest;
}

final class HintCredit extends PaymentHint {
  const new(this.extra);
  final Money extra;
}

/// E17: more than everything left for the whole kameti. Allowed, warned.
final class HintOverKameti extends PaymentHint {
  const new(this.leftForKameti);
  final Money leftForKameti;
}
