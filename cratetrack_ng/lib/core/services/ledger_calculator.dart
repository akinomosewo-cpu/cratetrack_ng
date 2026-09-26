import '../models/damage_claim.dart';
import '../models/ledger_entry.dart';

/// Pure, side-effect-free business logic for crate ledger and fee
/// calculations. Kept free of Flutter/Hive dependencies so it can be unit
/// tested in isolation.
class LedgerCalculator {
  const LedgerCalculator._();

  /// Outstanding balance owed by the current holder for a crate: the sum of
  /// charges (deposit, rental fees, penalties) minus credits (payments,
  /// refunds) recorded so far.
  static double outstandingBalance(List<LedgerEntry> entries) {
    var balance = 0.0;
    for (final entry in entries) {
      balance += entry.signedAmount;
    }
    return _roundCurrency(balance);
  }

  /// Total rental fee revenue collected across all entries (or a filtered
  /// subset), i.e. the sum of all rentalFee-type entries.
  static double totalRentalRevenue(List<LedgerEntry> entries) {
    final total = entries
        .where((e) => e.type == LedgerEntryType.rentalFee)
        .fold<double>(0, (sum, e) => sum + e.amount);
    return _roundCurrency(total);
  }

  /// Total value of deposits currently held (deposits recorded minus any
  /// refunds already paid out).
  static double totalDepositsHeld(List<LedgerEntry> entries) {
    final deposits = entries
        .where((e) => e.type == LedgerEntryType.deposit)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final refunds = entries
        .where((e) => e.type == LedgerEntryType.refund)
        .fold<double>(0, (sum, e) => sum + e.amount);
    return _roundCurrency(deposits - refunds);
  }

  /// Total value of approved damage claims against a crate.
  static double approvedDamageTotal(List<DamageClaim> claims) {
    final total = claims
        .where((c) => c.status == ClaimStatus.approved)
        .fold<double>(0, (sum, c) => sum + c.estimatedCost);
    return _roundCurrency(total);
  }

  /// How much of the original deposit should be refunded once a crate is
  /// returned, after deducting approved damage claims. Never negative.
  static double depositRefundDue(
    double depositAmount,
    List<DamageClaim> claims,
  ) {
    final damage = approvedDamageTotal(claims);
    final refund = depositAmount - damage;
    return _roundCurrency(refund < 0 ? 0 : refund);
  }

  /// The rental fee owed for [tripCount] trips at [feePerTrip] each.
  static double rentalFeeForTrips(double feePerTrip, int tripCount) {
    if (tripCount <= 0) return 0;
    return _roundCurrency(feePerTrip * tripCount);
  }

  static double _roundCurrency(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}
