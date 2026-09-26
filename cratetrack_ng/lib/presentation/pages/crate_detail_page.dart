import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/crate.dart';
import '../../core/models/custody_event.dart';
import '../../core/models/damage_claim.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/services/ledger_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/crate_bloc.dart';
import '../widgets/status_chip.dart';

final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM y, h:mm a');

class CrateDetailPage extends StatefulWidget {
  final String crateId;
  const CrateDetailPage({super.key, required this.crateId});

  @override
  State<CrateDetailPage> createState() => _CrateDetailPageState();
}

class _CrateDetailPageState extends State<CrateDetailPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrateBloc, CrateState>(
      builder: (context, state) {
        final crate = state.crates.firstWhere(
          (c) => c.id == widget.crateId,
          orElse: () => Crate(
            id: widget.crateId,
            label: 'Unknown',
            depositAmount: 0,
            rentalFeePerTrip: 0,
            createdAt: DateTime.now(),
          ),
        );
        final custody = state.custodyByCrate[widget.crateId] ?? [];
        final ledger = state.ledgerByCrate[widget.crateId] ?? [];
        final claims = state.claimsByCrate[widget.crateId] ?? [];
        final balance = LedgerCalculator.outstandingBalance(ledger);
        final refundDue = LedgerCalculator.depositRefundDue(crate.depositAmount, claims);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(crate.label, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(data: crate.id, size: 72, backgroundColor: Colors.white),
                ),
                const Gap(16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      StatusChip(status: crate.status),
                      const Gap(8),
                      Expanded(
                        child: Text('Held by ${crate.currentHolder ?? 'Unassigned'}',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const Gap(8),
                    Text('Deposit ${_currency.format(crate.depositAmount)} · Fee/trip ${_currency.format(crate.rentalFeePerTrip)}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const Gap(4),
                    Text('Balance owed: ${_currency.format(balance)}',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: balance > 0 ? AppColors.warning : AppColors.success, fontWeight: FontWeight.w700)),
                    Text('Deposit refund due: ${_currency.format(refundDue)}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
            ),
            const Gap(12),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Custody'),
                Tab(text: 'Ledger'),
                Tab(text: 'Damage'),
              ],
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: [
                _CustodyTab(crate: crate, custody: custody),
                _LedgerTab(crate: crate, entries: ledger),
                _DamageTab(crate: crate, claims: claims),
              ]),
            ),
          ]),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete crate?', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
        content: Text('This removes the crate record. History stays for auditing.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CrateBloc>().add(CrateDeleted(widget.crateId));
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _CustodyTab extends StatelessWidget {
  final Crate crate;
  final List<CustodyEvent> custody;
  const _CustodyTab({required this.crate, required this.custody});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (custody.isEmpty)
            Text('No custody transfers yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          for (final event in custody)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${event.fromStatus.label} → ${event.toStatus.label}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    const Gap(2),
                    Text('${event.location} · ${event.handledBy}',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                    Text(_dateFmt.format(event.timestamp),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 16,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.sync_alt_rounded, size: 18),
          label: const Text('Record Custody Transfer'),
          onPressed: () => _showTransferSheet(context),
        ),
      ),
    ]);
  }

  void _showTransferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<CrateBloc>(),
        child: _TransferSheet(crate: crate),
      ),
    );
  }
}

class _TransferSheet extends StatefulWidget {
  final Crate crate;
  const _TransferSheet({required this.crate});
  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  CustodyStatus? _status;
  final _locationCtrl = TextEditingController();
  final _handledByCtrl = TextEditingController();

  @override
  void dispose() {
    _locationCtrl.dispose();
    _handledByCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Record Custody Transfer', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
        const Gap(16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CustodyStatus.values.map((status) {
            final selected = _status == status;
            return ChoiceChip(
              label: Text(status.label),
              selected: selected,
              onSelected: (_) => setState(() => _status = status),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
            );
          }).toList(),
        ),
        const Gap(16),
        TextField(
          controller: _locationCtrl,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Location, e.g. Mile 12 Market'),
        ),
        const Gap(12),
        TextField(
          controller: _handledByCtrl,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Handled by (name/company)'),
        ),
        const Gap(20),
        ElevatedButton(
          onPressed: _canSubmit() ? _submit : null,
          child: const Text('Save Transfer'),
        ),
      ]),
    );
  }

  bool _canSubmit() =>
      _status != null && _locationCtrl.text.trim().isNotEmpty && _handledByCtrl.text.trim().isNotEmpty;

  void _submit() {
    context.read<CrateBloc>().add(CustodyTransferred(
          crateId: widget.crate.id,
          toStatus: _status!,
          location: _locationCtrl.text.trim(),
          handledBy: _handledByCtrl.text.trim(),
        ));
    Navigator.pop(context);
  }
}

class _LedgerTab extends StatelessWidget {
  final Crate crate;
  final List<LedgerEntry> entries;
  const _LedgerTab({required this.crate, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (entries.isEmpty)
            Text('No ledger entries yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          for (final entry in entries)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.type.label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    if (entry.note != null && entry.note!.isNotEmpty)
                      Text(entry.note!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    Text(_dateFmt.format(entry.timestamp),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
                  ]),
                ),
                Text(
                  '${entry.type.isCharge ? '+' : '-'}${_currency.format(entry.amount)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: entry.type.isCharge ? AppColors.warning : AppColors.success, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
        ],
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 16,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: const Text('Record Payment / Fee'),
          onPressed: () => _showLedgerSheet(context),
        ),
      ),
    ]);
  }

  void _showLedgerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(value: context.read<CrateBloc>(), child: _LedgerSheet(crate: crate)),
    );
  }
}

class _LedgerSheet extends StatefulWidget {
  final Crate crate;
  const _LedgerSheet({required this.crate});
  @override
  State<_LedgerSheet> createState() => _LedgerSheetState();
}

class _LedgerSheetState extends State<_LedgerSheet> {
  LedgerEntryType _type = LedgerEntryType.payment;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Record Ledger Entry', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
        const Gap(16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LedgerEntryType.values.map((type) {
            final selected = _type == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) => setState(() => _type = type),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
            );
          }).toList(),
        ),
        const Gap(16),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Amount (₦)'),
        ),
        const Gap(12),
        TextField(
          controller: _noteCtrl,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Note (optional)'),
        ),
        const Gap(20),
        ElevatedButton(onPressed: _submit, child: const Text('Save Entry')),
      ]),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    context.read<CrateBloc>().add(LedgerChargeRecorded(
          crateId: widget.crate.id,
          type: _type,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ));
    Navigator.pop(context);
  }
}

class _DamageTab extends StatelessWidget {
  final Crate crate;
  final List<DamageClaim> claims;
  const _DamageTab({required this.crate, required this.claims});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (claims.isEmpty)
            Text('No damage claims filed.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          for (final claim in claims)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(claim.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                  Text(_currency.format(claim.estimatedCost),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                ]),
                const Gap(4),
                if (claim.photoPath != null) ...[
                  const Gap(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(claim.photoPath!, height: 100, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                  const Gap(6),
                ],
                Row(children: [
                  Text('Reported by ${claim.reportedBy} · ${_dateFmt.format(claim.reportedAt)}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
                  const Spacer(),
                  _ClaimStatusChip(status: claim.status),
                ]),
                if (claim.status == ClaimStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      TextButton(
                        onPressed: () => context
                            .read<CrateBloc>()
                            .add(DamageClaimReviewed(claim, ClaimStatus.approved)),
                        child: const Text('Approve', style: TextStyle(color: AppColors.success)),
                      ),
                      TextButton(
                        onPressed: () => context
                            .read<CrateBloc>()
                            .add(DamageClaimReviewed(claim, ClaimStatus.rejected)),
                        child: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                      ),
                    ]),
                  ),
              ]),
            ),
        ],
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 16,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
          label: const Text('File Damage Claim'),
          onPressed: () => _showClaimSheet(context),
        ),
      ),
    ]);
  }

  void _showClaimSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(value: context.read<CrateBloc>(), child: _ClaimSheet(crate: crate)),
    );
  }
}

class _ClaimStatusChip extends StatelessWidget {
  final ClaimStatus status;
  const _ClaimStatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ClaimStatus.pending => AppColors.warning,
      ClaimStatus.approved => AppColors.success,
      ClaimStatus.rejected => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status.label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ClaimSheet extends StatefulWidget {
  final Crate crate;
  const _ClaimSheet({required this.crate});
  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _reporterCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _costCtrl.dispose();
    _reporterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('File Damage Claim', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
        const Gap(4),
        Text('A photo can be attached from the camera or gallery when reviewing the claim.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Gap(16),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Describe the damage'),
        ),
        const Gap(12),
        TextField(
          controller: _costCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Estimated repair/replacement cost (₦)'),
        ),
        const Gap(12),
        TextField(
          controller: _reporterCtrl,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Reported by'),
        ),
        const Gap(20),
        ElevatedButton(onPressed: _submit, child: const Text('Submit Claim')),
      ]),
    );
  }

  void _submit() {
    final cost = double.tryParse(_costCtrl.text);
    if (_descCtrl.text.trim().isEmpty || cost == null || cost < 0 || _reporterCtrl.text.trim().isEmpty) return;
    context.read<CrateBloc>().add(DamageClaimFiled(
          crateId: widget.crate.id,
          description: _descCtrl.text.trim(),
          estimatedCost: cost,
          reportedBy: _reporterCtrl.text.trim(),
        ));
    Navigator.pop(context);
  }
}
