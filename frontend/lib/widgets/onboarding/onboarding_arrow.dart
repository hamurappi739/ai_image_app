import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Direction the arrow tip points toward.
enum OnboardingArrowDirection {
  up,
  down,
  left,
  right,
  downRight,
  downLeft,
}

/// Accent label + curved arrow for onboarding mockups.
class OnboardingPointer extends StatelessWidget {
  const OnboardingPointer({
    super.key,
    required this.label,
    this.direction = OnboardingArrowDirection.down,
    this.compact = false,
  });

  final String label;
  final OnboardingArrowDirection direction;
  final bool compact;

  static const _accent = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final arrowSize = compact ? 36.0 : 44.0;

    final arrow = CustomPaint(
      size: Size(arrowSize, arrowSize),
      painter: _CurvedArrowPainter(
        direction: direction,
        color: _accent,
        strokeWidth: compact ? 2.6 : 3.2,
      ),
    );

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );

    switch (direction) {
      case OnboardingArrowDirection.up:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [arrow, const SizedBox(height: 4), chip],
        );
      case OnboardingArrowDirection.down:
      case OnboardingArrowDirection.downRight:
      case OnboardingArrowDirection.downLeft:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [chip, const SizedBox(height: 4), arrow],
        );
      case OnboardingArrowDirection.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [arrow, const SizedBox(width: 6), chip],
        );
      case OnboardingArrowDirection.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [chip, const SizedBox(width: 6), arrow],
        );
    }
  }
}

class _CurvedArrowPainter extends CustomPainter {
  _CurvedArrowPainter({
    required this.direction,
    required this.color,
    required this.strokeWidth,
  });

  final OnboardingArrowDirection direction;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    Offset tip;
    Offset control;
    Offset start;

    switch (direction) {
      case OnboardingArrowDirection.down:
        start = Offset(size.width * 0.2, size.height * 0.08);
        control = Offset(size.width * 0.75, size.height * 0.45);
        tip = Offset(size.width * 0.5, size.height * 0.92);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
      case OnboardingArrowDirection.up:
        start = Offset(size.width * 0.5, size.height * 0.92);
        control = Offset(size.width * 0.2, size.height * 0.45);
        tip = Offset(size.width * 0.72, size.height * 0.08);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
      case OnboardingArrowDirection.right:
        start = Offset(size.width * 0.08, size.height * 0.35);
        control = Offset(size.width * 0.55, size.height * 0.1);
        tip = Offset(size.width * 0.92, size.height * 0.55);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
      case OnboardingArrowDirection.left:
        start = Offset(size.width * 0.92, size.height * 0.55);
        control = Offset(size.width * 0.45, size.height * 0.82);
        tip = Offset(size.width * 0.08, size.height * 0.35);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
      case OnboardingArrowDirection.downRight:
        start = Offset(size.width * 0.1, size.height * 0.12);
        control = Offset(size.width * 0.55, size.height * 0.55);
        tip = Offset(size.width * 0.88, size.height * 0.88);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
      case OnboardingArrowDirection.downLeft:
        start = Offset(size.width * 0.9, size.height * 0.12);
        control = Offset(size.width * 0.45, size.height * 0.55);
        tip = Offset(size.width * 0.12, size.height * 0.88);
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
    }

    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, paint, tip, control);
  }

  void _drawArrowHead(Canvas canvas, Paint paint, Offset tip, Offset control) {
    final angle = math.atan2(tip.dy - control.dy, tip.dx - control.dx);
    const headLen = 9.0;
    const headAngle = 0.55;

    final p1 = Offset(
      tip.dx - headLen * math.cos(angle - headAngle),
      tip.dy - headLen * math.sin(angle - headAngle),
    );
    final p2 = Offset(
      tip.dx - headLen * math.cos(angle + headAngle),
      tip.dy - headLen * math.sin(angle + headAngle),
    );

    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.color != color;
}
