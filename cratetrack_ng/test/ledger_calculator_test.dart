import 'package:flutter_test/flutter_test.dart';
import 'package:cratetrack_ng/core/models/damage_claim.dart';
import 'package:cratetrack_ng/core/models/ledger_entry.dart';
import 'package:cratetrack_ng/core/services/ledger_calculator.dart';

LedgerEntry _entry(LedgerEntryType type, double amount, {String crateId = 'c1'}) {
  return LedgerEntry(
    id: '${type.name}-$amount',
    crateId: crateId,
    type: type,
    amount: amount,
    timestamp: DateTime(2026, 1, 1),
  );
}

DamageClaim _claim(double cost, ClaimStatus status, {String crateId = 'c1'}) {
  return DamageClaim(
    id: 'claim-$cost-${status.name}',
    crateId: crateId,
    description: 'test damage',
    estimatedCost: cost,
    status: status,
    reportedAt: DateTime(2026, 1, 1),
    reportedBy: 'tester',
  );
}

void main() {
  group('LedgerCalculator.outstandingBalance', () {
    test('sums charges and subtracts credits', () {
      final entries = [
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.rentalFee, 100),
        _entry(LedgerEntryType.rentalFee, 100),
        _entry(LedgerEntryType.payment, 150),
      ];
      expect(LedgerCalculator.outstandingBalance(entries), 550);
    });

    test('returns zero for an empty ledger', () {
      expect(LedgerCalculator.outstandingBalance([]), 0);
    });

    test('penalties increase the balance owed', () {
      final entries = [
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.penalty, 200),
      ];
      expect(LedgerCalculator.outstandingBalance(entries), 700);
    });

    test('refunds reduce the balance owed', () {
      final entries = [
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.refund, 500),
      ];
      expect(LedgerCalculator.outstandingBalance(entries), 0);
    });
  });

  group('LedgerCalculator.totalRentalRevenue', () {
    test('only counts rental fee entries', () {
      final entries = [
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.rentalFee, 100),
        _entry(LedgerEntryType.rentalFee, 150),
        _entry(LedgerEntryType.payment, 50),
      ];
      expect(LedgerCalculator.totalRentalRevenue(entries), 250);
    });
  });

  group('LedgerCalculator.totalDepositsHeld', () {
    test('subtracts refunds from deposits', () {
      final entries = [
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.deposit, 500),
        _entry(LedgerEntryType.refund, 300),
      ];
      expect(LedgerCalculator.totalDepositsHeld(entries), 700);
    });
  });

  group('LedgerCalculator.approvedDamageTotal', () {
    test('only sums approved claims', () {
      final claims = [
        _claim(100, ClaimStatus.approved),
        _claim(50, ClaimStatus.pending),
        _claim(75, ClaimStatus.rejected),
        _claim(25, ClaimStatus.approved),
      ];
      expect(LedgerCalculator.approvedDamageTotal(claims), 125);
    });
  });

  group('LedgerCalculator.depositRefundDue', () {
    test('deducts approved damage from deposit', () {
      final claims = [_claim(150, ClaimStatus.approved)];
      expect(LedgerCalculator.depositRefundDue(500, claims), 350);
    });

    test('never returns a negative refund', () {
      final claims = [_claim(900, ClaimStatus.approved)];
      expect(LedgerCalculator.depositRefundDue(500, claims), 0);
    });

    test('ignores pending and rejected claims', () {
      final claims = [
        _claim(200, ClaimStatus.pending),
        _claim(200, ClaimStatus.rejected),
      ];
      expect(LedgerCalculator.depositRefundDue(500, claims), 500);
    });
  });

  group('LedgerCalculator.rentalFeeForTrips', () {
    test('multiplies fee by trip count', () {
      expect(LedgerCalculator.rentalFeeForTrips(100, 3), 300);
    });

    test('returns zero for zero or negative trips', () {
      expect(LedgerCalculator.rentalFeeForTrips(100, 0), 0);
      expect(LedgerCalculator.rentalFeeForTrips(100, -2), 0);
    });

    test('rounds to two decimal places', () {
      expect(LedgerCalculator.rentalFeeForTrips(33.333, 3), 100.0);
    });
  });
}
