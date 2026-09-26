import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/models/crate.dart';
import '../../core/routing/app_transitions.dart';
import '../../core/services/ledger_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/crate_bloc.dart';
import '../widgets/animated_counter.dart';
import '../widgets/status_chip.dart';
import 'auth/login_page.dart';
import 'crate_detail_page.dart';
import 'register_crate_sheet.dart';
import 'scan_page.dart';

final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class DashboardPage extends StatelessWidget {
  final AuthRepository? authRepository;
  const DashboardPage({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<CrateBloc, CrateState>(
          builder: (context, state) {
            final crates = state.crates;
            final allLedger = state.ledgerByCrate.values.expand((e) => e).toList();
            final activeCount =
                crates.where((c) => c.status == CustodyStatus.inTransit || c.status == CustodyStatus.market).length;
            final damagedCount = crates.where((c) => c.status == CustodyStatus.damaged).length;
            final revenue = LedgerCalculator.totalRentalRevenue(allLedger);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: AppColors.background,
                  title: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 17),
                    ),
                    const Gap(10),
                    Text('CrateTrack NG',
                        style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textPrimary),
                      tooltip: 'Scan crate QR',
                      onPressed: () => _openScanner(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      tooltip: 'Register crate',
                      onPressed: () => _showRegisterSheet(context),
                    ),
                    if (authRepository != null)
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                        tooltip: 'Log out',
                        onPressed: () => _logOut(context),
                      ),
                    const Gap(4),
                  ],
                ),
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Gap(8),
                        Row(children: [
                          _StatCard(label: 'Crates', value: crates.length.toString(), color: AppColors.primary)
                              .animate(delay: 50.ms)
                              .fadeIn()
                              .slideY(begin: 0.1),
                          const Gap(12),
                          _StatCard(label: 'In Circulation', value: activeCount.toString(), color: AppColors.success)
                              .animate(delay: 100.ms)
                              .fadeIn()
                              .slideY(begin: 0.1),
                          const Gap(12),
                          _StatCard(label: 'Damaged', value: damagedCount.toString(), color: AppColors.danger)
                              .animate(delay: 150.ms)
                              .fadeIn()
                              .slideY(begin: 0.1),
                        ]),
                        const Gap(12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                            boxShadow: AppShadows.colored(AppColors.primary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TOTAL RENTAL REVENUE',
                                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white70, letterSpacing: 0.8)),
                              const Gap(6),
                              AnimatedCounter(
                                value: revenue,
                                formatter: (v) => _currency.format(v),
                                style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.1),
                        const Gap(28),
                        Text('Crate Inventory', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
                        const Gap(14),
                        if (crates.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 40),
                              ),
                              const Gap(18),
                              Text('No crates registered yet',
                                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
                              const Gap(6),
                              Text('Tap + to register your first crate',
                                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                            ]),
                          ).animate().fadeIn(delay: 250.ms)
                        else
                          ...crates.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _CrateTile(crate: e.value)
                                    .animate(delay: Duration(milliseconds: 40 * e.key))
                                    .fadeIn(),
                              )),
                        const Gap(32),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (_) => BlocProvider.value(value: context.read<CrateBloc>(), child: const RegisterCrateSheet()),
    );
  }

  void _openScanner(BuildContext context) async {
    final bloc = context.read<CrateBloc>();
    final crateId = await Navigator.of(context).push<String>(
      AppPageRoute(builder: (_) => const ScanPage()),
    );
    if (crateId == null) return;
    final crate = bloc.repository.getCrate(crateId);
    if (crate == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No crate found for this QR code')),
        );
      }
      return;
    }
    if (context.mounted) {
      Navigator.of(context).push(AppPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: CrateDetailPage(crateId: crateId)),
      ));
    }
  }

  Future<void> _logOut(BuildContext context) async {
    final repo = authRepository;
    if (repo == null) return;
    await repo.logOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute<void>(builder: (_) => LoginPage(authRepository: repo, crateRepository: context.read<CrateBloc>().repository)),
        (route) => false,
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.soft,
          ),
          child: Column(children: [
            AnimatedCounter(
              value: int.tryParse(value) ?? 0,
              formatter: (v) => v.toStringAsFixed(0),
              style: AppTextStyles.displaySmall.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            const Gap(4),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _CrateTile extends StatelessWidget {
  final Crate crate;
  const _CrateTile({required this.crate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => Navigator.of(context).push(AppPageRoute(
        builder: (_) => BlocProvider.value(value: context.read<CrateBloc>(), child: CrateDetailPage(crateId: crate.id)),
      )),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppShadows.soft,
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(crate.label, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
              const Gap(4),
              Text('Held by ${crate.currentHolder ?? 'Unassigned'}',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          StatusChip(status: crate.status),
          const Gap(8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
        ]),
      ),
    );
  }
}
