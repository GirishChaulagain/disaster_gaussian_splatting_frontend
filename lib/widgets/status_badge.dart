import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0x1A10B981); // 10% emerald
        textColor = const Color(0xFF34D399); // emerald-400
        icon = Icons.check_circle_outline;
        break;
      case 'processing':
        color = const Color(0x1AF59E0B); // 10% amber
        textColor = const Color(0xFFFBBF24); // amber-400
        icon = Icons.sync;
        break;
      case 'pending':
        color = const Color(0x1A9CA3AF); // 10% gray
        textColor = const Color(0xFFD1D5DB); // gray-300
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        color = const Color(0x1AEF4444); // 10% red
        textColor = const Color(0xFFF87171); // red-400
        icon = Icons.error_outline;
        break;
      default:
        color = const Color(0x1A6366F1); // 10% indigo
        textColor = const Color(0xFFA5B4FC); // indigo-300
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.toLowerCase() == 'processing')
            RotationTransition(
              turns: const AlwaysStoppedAnimation(0.5), // Wait, we can animate it, but a static simple icon is fine, or we can just show the icon
              child: Icon(icon, size: 14, color: textColor),
            )
          else
            Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;

    switch (severity.toLowerCase()) {
      case 'critical':
        color = const Color(0x26EF4444); // 15% red
        textColor = const Color(0xFFF87171);
        break;
      case 'high':
        color = const Color(0x26F59E0B); // 15% amber
        textColor = const Color(0xFFFBBF24);
        break;
      case 'medium':
        color = const Color(0x263B82F6); // 15% blue
        textColor = const Color(0xFF60A5FA);
        break;
      case 'low':
        color = const Color(0x2610B981); // 15% emerald
        textColor = const Color(0xFF34D399);
        break;
      default:
        color = const Color(0x269CA3AF);
        textColor = const Color(0xFFD1D5DB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
      ),
    );
  }
}
