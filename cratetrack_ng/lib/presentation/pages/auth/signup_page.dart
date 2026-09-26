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

/// Local sign-up screen. Creates an operator/business account stored in Hive
/// on-device; there is no backend involved.
class SignUpPage extends StatefulWidget {
  final AuthRepository authRepository;
  final CrateRepository crateRepository;
  const SignUpPage({super.key, required this.authRepository, required this.crateRepository});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
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
      await widget.authRepository.signUp(
        businessName: _nameController.text,
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
      appBar: AppBar(backgroundColor: AppColors.background),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create your account', style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary))
                    .animate()
                    .fadeIn()
                    .slideY(begin: 0.1),
                const Gap(6),
                Text(
                  'Set up your business to start tracking crates',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ).animate(delay: 60.ms).fadeIn(),
                const Gap(28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Operator / business name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your business name' : null,
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                const Gap(14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.1),
                const Gap(14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Password (min. 6 characters)',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.1),
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
                      : const Text('Sign Up'),
                ).animate(delay: 220.ms).fadeIn(),
                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
