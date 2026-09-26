import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../blocs/crate_bloc.dart';

class RegisterCrateSheet extends StatefulWidget {
  const RegisterCrateSheet({super.key});
  @override
  State<RegisterCrateSheet> createState() => _RegisterCrateSheetState();
}

class _RegisterCrateSheetState extends State<RegisterCrateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _depositCtrl = TextEditingController(text: '500');
  final _feeCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _labelCtrl.dispose();
    _depositCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Register New Crate', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
          const Gap(4),
          Text('A unique QR code will be generated for this crate.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Gap(20),
          TextFormField(
            controller: _labelCtrl,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Crate label, e.g. CR-0001'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a label' : null,
          ),
          const Gap(12),
          TextFormField(
            controller: _depositCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Deposit amount (₦)'),
            validator: _validateNumber,
          ),
          const Gap(12),
          TextFormField(
            controller: _feeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Rental fee per trip (₦)'),
            validator: _validateNumber,
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Register Crate'),
          ),
        ]),
      ),
    );
  }

  String? _validateNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(v);
    if (parsed == null || parsed < 0) return 'Enter a valid amount';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CrateBloc>().add(CrateRegistered(
          label: _labelCtrl.text.trim(),
          depositAmount: double.parse(_depositCtrl.text),
          rentalFeePerTrip: double.parse(_feeCtrl.text),
        ));
    Navigator.pop(context);
  }
}
