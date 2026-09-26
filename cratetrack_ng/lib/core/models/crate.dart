/// Custody status of a crate as it moves through the supply chain.
enum CustodyStatus { farm, inTransit, market, returned, damaged, lost }

extension CustodyStatusX on CustodyStatus {
  String get label {
    switch (this) {
      case CustodyStatus.farm:
        return 'At Farm';
      case CustodyStatus.inTransit:
        return 'In Transit';
      case CustodyStatus.market:
        return 'At Market';
      case CustodyStatus.returned:
        return 'Returned';
      case CustodyStatus.damaged:
        return 'Damaged';
      case CustodyStatus.lost:
        return 'Lost';
    }
  }

  static CustodyStatus fromName(String name) {
    return CustodyStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CustodyStatus.farm,
    );
  }
}

/// A single reusable plastic crate (RPC) tracked by QR code.
class Crate {
  final String id; // QR code payload / unique identifier
  final String label; // human friendly code, e.g. CR-0001
  final double depositAmount;
  final double rentalFeePerTrip;
  final CustodyStatus status;
  final String? currentHolder;
  final DateTime createdAt;

  const Crate({
    required this.id,
    required this.label,
    required this.depositAmount,
    required this.rentalFeePerTrip,
    this.status = CustodyStatus.farm,
    this.currentHolder,
    required this.createdAt,
  });

  Crate copyWith({
    String? label,
    double? depositAmount,
    double? rentalFeePerTrip,
    CustodyStatus? status,
    String? currentHolder,
  }) {
    return Crate(
      id: id,
      label: label ?? this.label,
      depositAmount: depositAmount ?? this.depositAmount,
      rentalFeePerTrip: rentalFeePerTrip ?? this.rentalFeePerTrip,
      status: status ?? this.status,
      currentHolder: currentHolder ?? this.currentHolder,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'depositAmount': depositAmount,
        'rentalFeePerTrip': rentalFeePerTrip,
        'status': status.name,
        'currentHolder': currentHolder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Crate.fromMap(Map<dynamic, dynamic> map) => Crate(
        id: map['id'] as String,
        label: map['label'] as String,
        depositAmount: (map['depositAmount'] as num).toDouble(),
        rentalFeePerTrip: (map['rentalFeePerTrip'] as num).toDouble(),
        status: CustodyStatusX.fromName(map['status'] as String? ?? 'farm'),
        currentHolder: map['currentHolder'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
