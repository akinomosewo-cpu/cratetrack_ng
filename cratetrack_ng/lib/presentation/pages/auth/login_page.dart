import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/routing/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/crate_repository.dart';
import '../../blocs/crate_bloc.dart';
import '../dashboard_page.dart';
import 'signup_page.dart';

/// Local sign-in screen. There is no backend: credentials are validated
/// against the account stored on-device by [AuthRepository].
class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;
  final CrateRepository crateRepository;
  const LoginPage({super.key, required this.authRepository, required this.crateRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.logIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute<void>(
          builder: (_) => BlocProvider(
            create: (_) => CrateBloc(widget.crateRepository)..add(const CratesLoaded()),
            child: DashboardPage(authRepository: widget.authRepository),
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const Gap(24),
                Text('Welcome back', style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary))
                    .animate(delay: 80.ms)
                    .fadeIn()
                    .slideY(begin: 0.1),
                const Gap(6),
                Text(
                  'Sign in to manage your crate ledger',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ).animate(delay: 120.ms).fadeIn(),
                const Gap(32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1),
                const Gap(14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                if (_error != null) ...[
                  const Gap(14),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
                ],
                const Gap(28),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Log In'),
                ).animate(delay: 240.ms).fadeIn(),
                const Gap(20),
                Center(
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).push(AppPageRoute<void>(
                              builder: (_) => SignUpPage(
                                authRepository: widget.authRepository,
                                crateRepository: widget.crateRepository,
                              ),
                            )),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                              text: 'Sign up',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
