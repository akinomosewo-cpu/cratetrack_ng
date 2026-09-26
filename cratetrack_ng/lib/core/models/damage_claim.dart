enum ClaimStatus { pending, approved, rejected }

extension ClaimStatusX on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }

  static ClaimStatus fromName(String name) {
    return ClaimStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ClaimStatus.pending,
    );
  }
}

/// A damage report filed against a crate, optionally with a photo, that can
/// be approved (deducted from the deposit) or rejected.
class DamageClaim {
  final String id;
  final String crateId;
  final String description;
  final double estimatedCost;
  final String? photoPath;
  final ClaimStatus status;
  final DateTime reportedAt;
  final String reportedBy;

  const DamageClaim({
    required this.id,
    required this.crateId,
    required this.description,
    required this.estimatedCost,
    this.photoPath,
    this.status = ClaimStatus.pending,
    required this.reportedAt,
    required this.reportedBy,
  });

  DamageClaim copyWith({ClaimStatus? status}) => DamageClaim(
        id: id,
        crateId: crateId,
        description: description,
        estimatedCost: estimatedCost,
        photoPath: photoPath,
        status: status ?? this.status,
        reportedAt: reportedAt,
        reportedBy: reportedBy,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'crateId': crateId,
        'description': description,
        'estimatedCost': estimatedCost,
        'photoPath': photoPath,
        'status': status.name,
        'reportedAt': reportedAt.toIso8601String(),
        'reportedBy': reportedBy,
      };

  factory DamageClaim.fromMap(Map<dynamic, dynamic> map) => DamageClaim(
        id: map['id'] as String,
        crateId: map['crateId'] as String,
        description: map['description'] as String,
        estimatedCost: (map['estimatedCost'] as num).toDouble(),
        photoPath: map['photoPath'] as String?,
        status: ClaimStatusX.fromName(map['status'] as String? ?? 'pending'),
        reportedAt: DateTime.parse(map['reportedAt'] as String),
        reportedBy: map['reportedBy'] as String,
      );
}
