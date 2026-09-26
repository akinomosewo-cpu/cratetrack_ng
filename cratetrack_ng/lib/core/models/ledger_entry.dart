/// Type of a ledger transaction against a crate account.
enum LedgerEntryType { deposit, rentalFee, payment, refund, penalty }

extension LedgerEntryTypeX on LedgerEntryType {
  String get label {
    switch (this) {
      case LedgerEntryType.deposit:
        return 'Deposit Held';
      case LedgerEntryType.rentalFee:
        return 'Rental Fee';
      case LedgerEntryType.payment:
        return 'Payment Received';
      case LedgerEntryType.refund:
        return 'Deposit Refund';
      case LedgerEntryType.penalty:
        return 'Damage Penalty';
    }
  }

  /// Whether this entry type increases the amount owed by the crate holder
  /// (a charge) as opposed to reducing it (a credit/payment).
  bool get isCharge =>
      this == LedgerEntryType.deposit ||
      this == LedgerEntryType.rentalFee ||
      this == LedgerEntryType.penalty;

  static LedgerEntryType fromName(String name) {
    return LedgerEntryType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => LedgerEntryType.rentalFee,
    );
  }
}

/// A single financial transaction tied to a crate: a deposit, a per-trip
/// rental fee, a payment received, a deposit refund, or a damage penalty.
class LedgerEntry {
  final String id;
  final String crateId;
  final LedgerEntryType type;
  final double amount; // always a positive magnitude
  final DateTime timestamp;
  final String? note;

  const LedgerEntry({
    required this.id,
    required this.crateId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  /// Signed amount: charges are positive (increase balance owed), credits
  /// (payments/refunds) are negative (reduce balance owed).
  double get signedAmount => type.isCharge ? amount : -amount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'crateId': crateId,
        'type': type.name,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory LedgerEntry.fromMap(Map<dynamic, dynamic> map) => LedgerEntry(
        id: map['id'] as String,
        crateId: map['crateId'] as String,
        type: LedgerEntryTypeX.fromName(map['type'] as String? ?? 'rentalFee'),
        amount: (map['amount'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        note: map['note'] as String?,
      );
}
