import 'package:flutter/material.dart';
import '../models/or_booking.dart';

class UrgencyChip extends StatelessWidget {
  final UrgencyLevel level;
  final EdgeInsets? padding;
  const UrgencyChip({super.key, required this.level, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(level);
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          color: colors.fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

_ChipColors _colorsFor(UrgencyLevel level) {
  switch (level) {
    case UrgencyLevel.e1WithinOneHour:
      return _ChipColors(bg: const Color(0xFFD32F2F), fg: Colors.white);
    case UrgencyLevel.e2WithinSixHours:
      return _ChipColors(bg: const Color(0xFFF57C00), fg: Colors.white);
    case UrgencyLevel.e3WithinTwentyFourHours:
      return _ChipColors(bg: const Color(0xFF388E3C), fg: Colors.white);
  }
}

class _ChipColors {
  final Color bg;
  final Color fg;
  const _ChipColors({required this.bg, required this.fg});
}
