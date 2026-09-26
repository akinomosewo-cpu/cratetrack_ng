import 'package:hive_flutter/hive_flutter.dart';

import '../core/models/crate.dart';
import '../core/models/custody_event.dart';
import '../core/models/damage_claim.dart';
import '../core/models/ledger_entry.dart';

/// Persists crates, custody history, ledger entries and damage claims using
/// Hive boxes of plain maps (no code generation required).
class CrateRepository {
  static const _cratesBox = 'crates_box';
  static const _custodyBox = 'custody_box';
  static const _ledgerBox = 'ledger_box';
  static const _claimsBox = 'claims_box';

  Box? _crates;
  Box? _custody;
  Box? _ledger;
  Box? _claims;

  /// Initializes Hive storage. Pass [testDirectoryPath] in tests to avoid
  /// depending on the path_provider platform channel.
  Future<void> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      Hive.init(testDirectoryPath);
    } else {
      await Hive.initFlutter();
    }
    _crates = await Hive.openBox(_cratesBox);
    _custody = await Hive.openBox(_custodyBox);
    _ledger = await Hive.openBox(_ledgerBox);
    _claims = await Hive.openBox(_claimsBox);
  }

  // ---- Crates ----

  List<Crate> getAllCrates() {
    return _crates!.values
        .map((e) => Crate.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Crate? getCrate(String id) {
    final raw = _crates!.get(id);
    if (raw == null) return null;
    return Crate.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  Future<void> saveCrate(Crate crate) async {
    await _crates!.put(crate.id, crate.toMap());
  }

  Future<void> deleteCrate(String id) async {
    await _crates!.delete(id);
  }

  // ---- Custody events ----

  List<CustodyEvent> getCustodyEvents(String crateId) {
    return _custody!.values
        .map((e) => CustodyEvent.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.crateId == crateId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addCustodyEvent(CustodyEvent event) async {
    await _custody!.put(event.id, event.toMap());
  }

  // ---- Ledger entries ----

  List<LedgerEntry> getLedgerEntries(String crateId) {
    return _ledger!.values
        .map((e) => LedgerEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.crateId == crateId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<LedgerEntry> getAllLedgerEntries() {
    return _ledger!.values
        .map((e) => LedgerEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    await _ledger!.put(entry.id, entry.toMap());
  }

  // ---- Damage claims ----

  List<DamageClaim> getDamageClaims(String crateId) {
    return _claims!.values
        .map((e) => DamageClaim.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.crateId == crateId)
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<DamageClaim> getAllDamageClaims() {
    return _claims!.values
        .map((e) => DamageClaim.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  Future<void> saveDamageClaim(DamageClaim claim) async {
    await _claims!.put(claim.id, claim.toMap());
  }
}
