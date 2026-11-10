import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations_en.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Rows shaped exactly as PostgREST returns them (snake_case, bigint as
/// int, dates as YYYY-MM-DD).
void main() {
  group('models parse backend rows', () {
    test('Kameti', () {
      final k = Kameti.fromJson(const {
        'id': 'k1',
        'owner_id': 'u1',
        'name': 'Office Kameti 2026',
        'description': null,
        'start_month': '2026-10-01',
        'months_n': 20,
        'slot_amount_c': 250000,
        'due_day': 10,
        'reminder_days': [1, 5, 8, 10],
        'max_slots_per_member': 6,
        'status': 'active',
        'privacy_settings': {'show_amounts': true},
        'created_at': '2026-11-09T19:59:09.123+00:00',
        'started_at': '2026-11-09T20:00:00+00:00',
      });
      expect(k.slotAmountC, const Money(250000));
      expect(k.pot, const Money(5000000));
      expect(k.startMonth, DateTime.utc(2026, 10));
      expect(k.status, KametiStatus.active);
      expect(k.isOwnedBy('u1'), isTrue);
      expect(k.isOwnedBy('u2'), isFalse);
      expect(k.isOwnedBy(null), isFalse);
    });

    test('Member and Share', () {
      final m = Member.fromJson(const {
        'id': 'm1',
        'kameti_id': 'k1',
        'name': 'Ali Raza',
        'join_status': 'pending_approval',
        'contact_id': null,
        'profile_id': null,
      });
      expect(m.joinStatus, JoinStatus.pendingApproval);

      final s = Share.fromJson(const {
        'id': 's1',
        'kameti_id': 'k1',
        'slot_id': 'sl1',
        'member_id': 'm1',
        'monthly_amount': 125000,
        'effective_from_month': 1,
        'effective_to_month': null,
      });
      expect(s.monthlyAmount, const Money(125000));
    });

    test('Payment with bank transfer and void', () {
      final p = Payment.fromJson(const {
        'id': 'p1',
        'kameti_id': 'k1',
        'member_id': 'm1',
        'amount': 450000,
        'received_on': '2026-11-09',
        'method': 'bank_transfer',
        'created_at': '2026-11-09T10:00:00+00:00',
        'voided_at': '2026-11-09T11:00:00+00:00',
        'void_reason': 'wrong member',
      });
      expect(p.method, PaymentMethod.bankTransfer);
      expect(p.receivedOn, DateTime.utc(2026, 11, 9));
      expect(p.isVoided, isTrue);
    });

    test('ledger view rows', () {
      final c = MonthCollectionRow.fromJson(const {
        'kameti_id': 'k1',
        'month_index': 1,
        'month_start': '2026-10-01',
        'is_current': false,
        'target': 5000000,
        'received': 4970000,
        'covered': 4845000,
        'paid_count': 11,
        'member_count': 15,
        'payout_shortfall': 30000,
        'paid_out': 4970000,
        'recipients': 1,
        'recipients_paid': 1,
        'paid_out_short_by': 30000,
        'state': 'paid_out_short',
      });
      expect(c.state, MonthCollectionState.paidOutShort);
      expect(c.payoutShortfall, const Money(30000));

      final m = MemberMonthRow.fromJson(const {
        'kameti_id': 'k1',
        'member_id': 'm1',
        'month_index': 3,
        'month_start': '2026-12-01',
        'is_current': false,
        'due': 375000,
        'allocated': 180000,
        'remaining': 195000,
        'status': 'advance',
      });
      expect(m.status, MonthStatusCode.advance);

      final b = MemberBalanceRow.fromJson(const {
        'kameti_id': 'k1',
        'member_id': 'm1',
        'current_month_index': 2,
        'monthly_due': 125000,
        'due_to_date': 250000,
        'total_paid': 300000,
        'balance': -50000,
        'owes': 0,
        'credit': 50000,
      });
      expect(b.credit, const Money(50000));
    });
  });

  group('inputs serialise for RPCs', () {
    test('ShareInput and BatchPaymentItem', () {
      expect(
        const ShareInput(memberId: 'm1', monthlyAmount: Money(125000)).toJson(),
        {'member_id': 'm1', 'monthly_amount': 125000},
      );
      expect(
        const BatchPaymentItem(
          memberId: 'm1',
          amount: Money(50000),
          idempotencyKey: 'key-1',
        ).toJson(),
        {'member_id': 'm1', 'amount': 50000, 'idempotency_key': 'key-1'},
      );
    });

    test('dates go out as YYYY-MM-DD', () {
      expect(
        DateOnlyConverter.toDateString(DateTime.utc(2026, 3, 5)),
        '2026-03-05',
      );
    });
  });

  group('Result and Failure', () {
    test('guard turns RPC errors into ServerFailure codes', () async {
      final r = await Result.guard<int>(
        () => throw const PostgrestException(
          message: 'shares_must_sum_to_slot_amount',
          details: 'Shares add up to 200000, not 250000.',
          code: '22023',
        ),
      );
      final failure = (r as Err<int>).failure;
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 'shares_must_sum_to_slot_amount');
      expect(r.getOrThrow, throwsA(isA<ServerFailure>()));
    });

    test('network errors become NetworkFailure', () async {
      final r = await Result.guard<int>(
        () => throw const SocketException('offline'),
      );
      expect((r as Err<int>).failure, isA<NetworkFailure>());
    });

    test('messages for known and unknown codes', () {
      final l10n = AppLocalizationsEn();
      expect(
        failureMessage(
          l10n,
          const ServerFailure(code: 'shares_must_sum_to_slot_amount'),
        ),
        l10n.errSharesMustSum,
      );
      expect(
        failureMessage(l10n, const ServerFailure(code: 'something_new')),
        l10n.errUnknown,
      );
      expect(failureMessage(l10n, const NetworkFailure()), l10n.errNetwork);
    });
  });
}
