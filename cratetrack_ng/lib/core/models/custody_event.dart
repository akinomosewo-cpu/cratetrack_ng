import 'crate.dart';

/// A record of a crate's custody moving from one party/location to another.
class CustodyEvent {
  final String id;
  final String crateId;
  final CustodyStatus fromStatus;
  final CustodyStatus toStatus;
  final String location;
  final String handledBy;
  final DateTime timestamp;
  final String? note;

  const CustodyEvent({
    required this.id,
    required this.crateId,
    required this.fromStatus,
    required this.toStatus,
    required this.location,
    required this.handledBy,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'crateId': crateId,
        'fromStatus': fromStatus.name,
        'toStatus': toStatus.name,
        'location': location,
        'handledBy': handledBy,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory CustodyEvent.fromMap(Map<dynamic, dynamic> map) => CustodyEvent(
        id: map['id'] as String,
        crateId: map['crateId'] as String,
        fromStatus: CustodyStatusX.fromName(map['fromStatus'] as String? ?? 'farm'),
        toStatus: CustodyStatusX.fromName(map['toStatus'] as String? ?? 'farm'),
        location: map['location'] as String,
        handledBy: map['handledBy'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        note: map['note'] as String?,
      );
}
