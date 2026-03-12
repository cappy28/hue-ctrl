import 'package:flutter/material.dart';
import 'dart:math';

class BulbWidget extends StatefulWidget {
  final Color  color;
  final bool   isOn;
  final double brightness; // 0..1
  final String label;
  const BulbWidget({super.key, required this.color, required this.isOn, required this.brightness, required this.label});

  @override
  State<BulbWidget> createState() => _BulbWidgetState();
}

class _BulbWidgetState extends State<BulbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80, height: 110,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final gFactor = widget.isOn ? _glow.value * widget.brightness : 0.0;
              return CustomPaint(painter: _BulbPainter(widget.color, widget.isOn, gFactor));
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(widget.label,
          style: const TextStyle(color: Color(0x66E0E0F0), fontSize: 10, letterSpacing: 2),
        ),
      ],
    );
  }
}

class _BulbPainter extends CustomPainter {
  final Color  color;
  final bool   isOn;
  final double glowFactor;
  _BulbPainter(this.color, this.isOn, this.glowFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Glow halo
    if (isOn && glowFactor > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.25 * glowFactor)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(cx, 38), 50 * glowFactor, glowPaint);
    }

    // Bulb body path
    final path = Path();
    path.moveTo(cx, 8);
    path.cubicTo(cx - 18, 8, cx - 30, 22, cx - 30, 38);
    path.cubicTo(cx - 30, 52, cx - 22, 62, cx - 14, 70);
    path.cubicTo(cx - 12, 73, cx - 12, 78, cx - 12, 82);
    path.lineTo(cx + 12, 82);
    path.cubicTo(cx + 12, 78, cx + 12, 73, cx + 14, 70);
    path.cubicTo(cx + 22, 62, cx + 30, 52, cx + 30, 38);
    path.cubicTo(cx + 30, 22, cx + 18, 8, cx, 8);
    path.close();

    if (isOn) {
      final grad = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [color, color.withOpacity(0.6)],
      ).createShader(Rect.fromLTWH(cx - 30, 8, 60, 80));
      canvas.drawPath(path, Paint()..shader = grad);

      if (glowFactor > 0) {
        final glowEdge = Paint()
          ..color = color.withOpacity(0.5 * glowFactor)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawPath(path, glowEdge);
      }
    } else {
      canvas.drawPath(path, Paint()..color = const Color(0xFF2A2A3A));
    }

    canvas.drawPath(path, Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Highlight
    if (isOn) {
      final hilite = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.save();
      canvas.translate(cx - 8, 20);
      canvas.rotate(-0.35);
      canvas.drawOval(const Rect.fromLTWH(-5, -8, 10, 16), hilite);
      canvas.restore();
    }

    // Base rings
    final basePaint = Paint()..color = const Color(0xFF555566);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-12, 82, 24, 5), const Radius.circular(2)), basePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-10, 87, 20, 5), const Radius.circular(1)), Paint()..color = const Color(0xFF666677));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-8,  92, 16, 6), const Radius.circular(2)), Paint()..color = const Color(0xFF777788));
  }

  @override
  bool shouldRepaint(_BulbPainter old) =>
      old.color != color || old.isOn != isOn || old.glowFactor != glowFactor;
}
