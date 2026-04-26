import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A security overlay widget that displays a watermark with user info
/// to deter screen capture/photo leaks.
class SecurityOverlay extends StatelessWidget {
  const SecurityOverlay({
    super.key,
    required this.child,
    this.enabled = false,
    this.showEmail = true,
    this.showTimestamp = true,
    this.opacity = 0.05,
  });

  final Widget child;
  final bool enabled;
  final bool showEmail;
  final bool showTimestamp;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WatermarkPainter(
                email: showEmail ? _getUserEmail() : null,
                timestamp: showTimestamp ? _getCurrentTimestamp() : null,
                opacity: opacity,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _getUserEmail() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user?.email;
    } catch (_) {
      return null;
    }
  }

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    this.email,
    this.timestamp,
    required this.opacity,
  });

  final String? email;
  final String? timestamp;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (email == null && timestamp == null) return;

    final text = [email, timestamp].whereType<String>().join(' | ');
    if (text.isEmpty) return;

    final textStyle = TextStyle(
      color: Colors.grey.withValues(alpha: opacity * 255),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw diagonal watermarks across the screen
    const spacing = 200.0;
    const angle = -0.5; // ~-28 degrees

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);

    for (double y = -size.height; y < size.height * 2; y += spacing) {
      for (double x = -size.width;
          x < size.width * 2;
          x += textPainter.width + 50) {
        textPainter.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter oldDelegate) {
    return oldDelegate.email != email ||
        oldDelegate.timestamp != timestamp ||
        oldDelegate.opacity != opacity;
  }
}
