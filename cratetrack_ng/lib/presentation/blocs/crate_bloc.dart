import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/crate.dart';
import '../../core/models/custody_event.dart';
import '../../core/models/damage_claim.dart';
import '../../core/models/ledger_entry.dart';
import '../../data/crate_repository.dart';

const _uuid = Uuid();

// ---- Events ----

abstract class CrateEvent extends Equatable {
  const CrateEvent();
  @override
  List<Object?> get props => [];
}

class CratesLoaded extends CrateEvent {
  const CratesLoaded();
}

class CrateRegistered extends CrateEvent {
  final String label;
  final double depositAmount;
  final double rentalFeePerTrip;
  const CrateRegistered({
    required this.label,
    required this.depositAmount,
    required this.rentalFeePerTrip,
  });
  @override
  List<Object?> get props => [label, depositAmount, rentalFeePerTrip];
}

class CrateDeleted extends CrateEvent {
  final String id;
  const CrateDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class CustodyTransferred extends CrateEvent {
  final String crateId;
  final CustodyStatus toStatus;
  final String location;
  final String handledBy;
  final String? note;
  const CustodyTransferred({
    required this.crateId,
    required this.toStatus,
    required this.location,
    required this.handledBy,
    this.note,
  });
  @override
  List<Object?> get props => [crateId, toStatus, location, handledBy, note];
}

class LedgerChargeRecorded extends CrateEvent {
  final String crateId;
  final LedgerEntryType type;
  final double amount;
  final String? note;
  const LedgerChargeRecorded({
    required this.crateId,
    required this.type,
    required this.amount,
    this.note,
  });
  @override
  List<Object?> get props => [crateId, type, amount, note];
}

class DamageClaimFiled extends CrateEvent {
  final String crateId;
  final String description;
  final double estimatedCost;
  final String? photoPath;
  final String reportedBy;
  const DamageClaimFiled({
    required this.crateId,
    required this.description,
    required this.estimatedCost,
    this.photoPath,
    required this.reportedBy,
  });
  @override
  List<Object?> get props =>
      [crateId, description, estimatedCost, photoPath, reportedBy];
}

class DamageClaimReviewed extends CrateEvent {
  final DamageClaim claim;
  final ClaimStatus status;
  const DamageClaimReviewed(this.claim, this.status);
  @override
  List<Object?> get props => [claim.id, status];
}

// ---- State ----

class CrateState extends Equatable {
  final bool isLoading;
  final List<Crate> crates;
  final Map<String, List<CustodyEvent>> custodyByCrate;
  final Map<String, List<LedgerEntry>> ledgerByCrate;
  final Map<String, List<DamageClaim>> claimsByCrate;
  final String? errorMessage;

  const CrateState({
    this.isLoading = true,
    this.crates = const [],
    this.custodyByCrate = const {},
    this.ledgerByCrate = const {},
    this.claimsByCrate = const {},
    this.errorMessage,
  });

  CrateState copyWith({
    bool? isLoading,
    List<Crate>? crates,
    Map<String, List<CustodyEvent>>? custodyByCrate,
    Map<String, List<LedgerEntry>>? ledgerByCrate,
    Map<String, List<DamageClaim>>? claimsByCrate,
    String? errorMessage,
  }) {
    return CrateState(
      isLoading: isLoading ?? this.isLoading,
      crates: crates ?? this.crates,
      custodyByCrate: custodyByCrate ?? this.custodyByCrate,
      ledgerByCrate: ledgerByCrate ?? this.ledgerByCrate,
      claimsByCrate: claimsByCrate ?? this.claimsByCrate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, crates, custodyByCrate, ledgerByCrate, claimsByCrate, errorMessage];
}

// ---- Bloc ----

class CrateBloc extends Bloc<CrateEvent, CrateState> {
  final CrateRepository repository;

  CrateBloc(this.repository) : super(const CrateState()) {
    on<CratesLoaded>(_onLoaded);
    on<CrateRegistered>(_onRegistered);
    on<CrateDeleted>(_onDeleted);
    on<CustodyTransferred>(_onCustodyTransferred);
    on<LedgerChargeRecorded>(_onLedgerRecorded);
    on<DamageClaimFiled>(_onClaimFiled);
    on<DamageClaimReviewed>(_onClaimReviewed);
  }

  void _refreshDetail(CrateState state, String crateId, Emitter<CrateState> emit) {
    final custody = Map<String, List<CustodyEvent>>.from(state.custodyByCrate);
    custody[crateId] = repository.getCustodyEvents(crateId);
    final ledger = Map<String, List<LedgerEntry>>.from(state.ledgerByCrate);
    ledger[crateId] = repository.getLedgerEntries(crateId);
    final claims = Map<String, List<DamageClaim>>.from(state.claimsByCrate);
    claims[crateId] = repository.getDamageClaims(crateId);
    emit(state.copyWith(
      crates: repository.getAllCrates(),
      custodyByCrate: custody,
      ledgerByCrate: ledger,
      claimsByCrate: claims,
    ));
  }

  Future<void> _onLoaded(CratesLoaded event, Emitter<CrateState> emit) async {
    final crates = repository.getAllCrates();
    final custody = <String, List<CustodyEvent>>{};
    final ledger = <String, List<LedgerEntry>>{};
    final claims = <String, List<DamageClaim>>{};
    for (final crate in crates) {
      custody[crate.id] = repository.getCustodyEvents(crate.id);
      ledger[crate.id] = repository.getLedgerEntries(crate.id);
      claims[crate.id] = repository.getDamageClaims(crate.id);
    }
    emit(state.copyWith(
      isLoading: false,
      crates: crates,
      custodyByCrate: custody,
      ledgerByCrate: ledger,
      claimsByCrate: claims,
    ));
  }

  Future<void> _onRegistered(CrateRegistered event, Emitter<CrateState> emit) async {
    final id = _uuid.v4();
    final crate = Crate(
      id: id,
      label: event.label,
      depositAmount: event.depositAmount,
      rentalFeePerTrip: event.rentalFeePerTrip,
      status: CustodyStatus.farm,
      currentHolder: 'Farm',
      createdAt: DateTime.now(),
    );
    await repository.saveCrate(crate);
    if (event.depositAmount > 0) {
      await repository.addLedgerEntry(LedgerEntry(
        id: _uuid.v4(),
        crateId: id,
        type: LedgerEntryType.deposit,
        amount: event.depositAmount,
        timestamp: DateTime.now(),
        note: 'Initial deposit on registration',
      ));
    }
    _refreshDetail(state, id, emit);
  }

  Future<void> _onDeleted(CrateDeleted event, Emitter<CrateState> emit) async {
    await repository.deleteCrate(event.id);
    emit(state.copyWith(crates: repository.getAllCrates()));
  }

  Future<void> _onCustodyTransferred(
      CustodyTransferred event, Emitter<CrateState> emit) async {
    final crate = repository.getCrate(event.crateId);
    if (crate == null) return;
    await repository.addCustodyEvent(CustodyEvent(
      id: _uuid.v4(),
      crateId: event.crateId,
      fromStatus: crate.status,
      toStatus: event.toStatus,
      location: event.location,
      handledBy: event.handledBy,
      timestamp: DateTime.now(),
      note: event.note,
    ));
    final updated = crate.copyWith(status: event.toStatus, currentHolder: event.handledBy);
    await repository.saveCrate(updated);

    // A trip completed (crate moved into transit) triggers a rental fee.
    if (event.toStatus == CustodyStatus.inTransit) {
      await repository.addLedgerEntry(LedgerEntry(
        id: _uuid.v4(),
        crateId: event.crateId,
        type: LedgerEntryType.rentalFee,
        amount: crate.rentalFeePerTrip,
        timestamp: DateTime.now(),
        note: 'Rental fee for trip to ${event.location}',
      ));
    }
    _refreshDetail(state, event.crateId, emit);
  }

  Future<void> _onLedgerRecorded(
      LedgerChargeRecorded event, Emitter<CrateState> emit) async {
    await repository.addLedgerEntry(LedgerEntry(
      id: _uuid.v4(),
      crateId: event.crateId,
      type: event.type,
      amount: event.amount,
      timestamp: DateTime.now(),
      note: event.note,
    ));
    _refreshDetail(state, event.crateId, emit);
  }

  Future<void> _onClaimFiled(DamageClaimFiled event, Emitter<CrateState> emit) async {
    await repository.saveDamageClaim(DamageClaim(
      id: _uuid.v4(),
      crateId: event.crateId,
      description: event.description,
      estimatedCost: event.estimatedCost,
      photoPath: event.photoPath,
      reportedAt: DateTime.now(),
      reportedBy: event.reportedBy,
    ));
    final crate = repository.getCrate(event.crateId);
    if (crate != null) {
      await repository.saveCrate(crate.copyWith(status: CustodyStatus.damaged));
    }
    _refreshDetail(state, event.crateId, emit);
  }

  Future<void> _onClaimReviewed(
      DamageClaimReviewed event, Emitter<CrateState> emit) async {
    final updatedClaim = event.claim.copyWith(status: event.status);
    await repository.saveDamageClaim(updatedClaim);
    if (event.status == ClaimStatus.approved) {
      await repository.addLedgerEntry(LedgerEntry(
        id: _uuid.v4(),
        crateId: event.claim.crateId,
        type: LedgerEntryType.penalty,
        amount: event.claim.estimatedCost,
        timestamp: DateTime.now(),
        note: 'Damage penalty: ${event.claim.description}',
      ));
    }
    _refreshDetail(state, event.claim.crateId, emit);
  }
}
