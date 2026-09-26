import 'package:flutter/material.dart';

import '../../core/models/crate.dart';
import '../../core/theme/app_theme.dart';

Color colorForStatus(CustodyStatus status) {
  switch (status) {
    case CustodyStatus.farm:
      return AppColors.primary;
    case CustodyStatus.inTransit:
      return AppColors.warning;
    case CustodyStatus.market:
      return AppColors.success;
    case CustodyStatus.returned:
      return AppColors.textSecondary;
    case CustodyStatus.damaged:
      return AppColors.danger;
    case CustodyStatus.lost:
      return AppColors.danger;
  }
}

class StatusChip extends StatelessWidget {
  final CustodyStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
