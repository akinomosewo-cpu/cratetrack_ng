import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/routing/app_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../../data/crate_repository.dart';
import '../blocs/crate_bloc.dart';
import 'auth/login_page.dart';
import 'dashboard_page.dart';

/// Brief animated brand reveal shown on cold start while the auth state is
/// checked, then hands off to the dashboard (returning users) or the login
/// screen (new/logged-out users).
class SplashPage extends StatefulWidget {
  final AuthRepository authRepository;
  final CrateRepository crateRepository;
  const SplashPage({super.key, required this.authRepository, required this.crateRepository});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
    final loggedIn = widget.authRepository.isLoggedIn();
    Navigator.of(context).pushReplacement(AppPageRoute<void>(
      builder: (_) => loggedIn
          ? BlocProvider(
              create: (_) => CrateBloc(widget.crateRepository)..add(const CratesLoaded()),
              child: DashboardPage(authRepository: widget.authRepository),
            )
          : LoginPage(authRepository: widget.authRepository, crateRepository: widget.crateRepository),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.colored(AppColors.primary),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 48),
            )
                .animate()
                .scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            Text(
              'CrateTrack NG',
              style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              'Reusable crate ledger for produce transport',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate(delay: 420.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
