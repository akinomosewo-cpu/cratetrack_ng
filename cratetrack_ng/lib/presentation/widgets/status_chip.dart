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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          status.label,
          style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
