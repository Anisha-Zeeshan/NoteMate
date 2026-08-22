import 'package:flutter/material.dart';

class AvatarOption {
  final String id;
  final String label;
  final Color skinTone;
  final Color hairColor;
  final Color outfitColor;
  final bool isFemale;
  final AvatarStyle style;

  const AvatarOption({
    required this.id,
    required this.label,
    required this.skinTone,
    required this.hairColor,
    required this.outfitColor,
    required this.isFemale,
    required this.style,
  });
}

enum AvatarStyle { casual, student, formal, cool, sporty, artistic }

const List<AvatarOption> kAvatars = [
  AvatarOption(id: 'f1', label: 'Student', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF2C1810), outfitColor: Color(0xFFAD1457), isFemale: true, style: AvatarStyle.student),
  AvatarOption(id: 'f2', label: 'Casual', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF1A1A1A), outfitColor: Color(0xFF3949AB), isFemale: true, style: AvatarStyle.casual),
  AvatarOption(id: 'f3', label: 'Formal', skinTone: Color(0xFFF4C2A1), hairColor: Color(0xFF6D3B2E), outfitColor: Color(0xFF37474F), isFemale: true, style: AvatarStyle.formal),
  AvatarOption(id: 'f4', label: 'Cool', skinTone: Color(0xFFD4A276), hairColor: Color(0xFF1C1C1C), outfitColor: Color(0xFF00897B), isFemale: true, style: AvatarStyle.cool),
  AvatarOption(id: 'f5', label: 'Sporty', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF8B4513), outfitColor: Color(0xFFE65100), isFemale: true, style: AvatarStyle.sporty),
  AvatarOption(id: 'f6', label: 'Artistic', skinTone: Color(0xFFF4C2A1), hairColor: Color(0xFF7B1FA2), outfitColor: Color(0xFFFFC107), isFemale: true, style: AvatarStyle.artistic),
  AvatarOption(id: 'f7', label: 'Classic', skinTone: Color(0xFFAB8B6A), hairColor: Color(0xFF1C1C1C), outfitColor: Color(0xFF1565C0), isFemale: true, style: AvatarStyle.student),
  AvatarOption(id: 'f8', label: 'Trendy', skinTone: Color(0xFF7D5A45), hairColor: Color(0xFF0D0D0D), outfitColor: Color(0xFFAD1457), isFemale: true, style: AvatarStyle.casual),
  AvatarOption(id: 'm1', label: 'Student', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF1A1A1A), outfitColor: Color(0xFF1565C0), isFemale: false, style: AvatarStyle.student),
  AvatarOption(id: 'm2', label: 'Casual', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF3D2B1F), outfitColor: Color(0xFF00897B), isFemale: false, style: AvatarStyle.casual),
  AvatarOption(id: 'm3', label: 'Formal', skinTone: Color(0xFFF4C2A1), hairColor: Color(0xFF2C1810), outfitColor: Color(0xFF212121), isFemale: false, style: AvatarStyle.formal),
  AvatarOption(id: 'm4', label: 'Cool', skinTone: Color(0xFFD4A276), hairColor: Color(0xFF0D0D0D), outfitColor: Color(0xFFE65100), isFemale: false, style: AvatarStyle.cool),
  AvatarOption(id: 'm5', label: 'Sporty', skinTone: Color(0xFFFFDBAC), hairColor: Color(0xFF8B4513), outfitColor: Color(0xFF2E7D32), isFemale: false, style: AvatarStyle.sporty),
  AvatarOption(id: 'm6', label: 'Artistic', skinTone: Color(0xFFF4C2A1), hairColor: Color(0xFF6D3B2E), outfitColor: Color(0xFF7B1FA2), isFemale: false, style: AvatarStyle.artistic),
  AvatarOption(id: 'm7', label: 'Classic', skinTone: Color(0xFFAB8B6A), hairColor: Color(0xFF1C1C1C), outfitColor: Color(0xFFAD1457), isFemale: false, style: AvatarStyle.student),
  AvatarOption(id: 'm8', label: 'Trendy', skinTone: Color(0xFF7D5A45), hairColor: Color(0xFF0D0D0D), outfitColor: Color(0xFF37474F), isFemale: false, style: AvatarStyle.casual),
];

class AvatarPainter extends CustomPainter {
  final AvatarOption avatar;
  AvatarPainter(this.avatar);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final p = Paint()..isAntiAlias = true;

    // Background
    p.color = avatar.outfitColor.withOpacity(0.18);
    canvas.drawCircle(Offset(cx, h / 2), w / 2, p);

    // ── Shoulders / Body ──────────────────────
    p.color = avatar.outfitColor;
    final bodyPath = Path();
    if (avatar.isFemale) {
      // Rounded shoulder shape
      bodyPath.moveTo(cx - w * 0.42, h);
      bodyPath.quadraticBezierTo(cx - w * 0.38, h * 0.72, cx - w * 0.22, h * 0.68);
      bodyPath.quadraticBezierTo(cx, h * 0.72, cx + w * 0.22, h * 0.68);
      bodyPath.quadraticBezierTo(cx + w * 0.38, h * 0.72, cx + w * 0.42, h);
    } else {
      // Broader male shoulders
      bodyPath.moveTo(cx - w * 0.48, h);
      bodyPath.quadraticBezierTo(cx - w * 0.44, h * 0.70, cx - w * 0.26, h * 0.66);
      bodyPath.quadraticBezierTo(cx, h * 0.70, cx + w * 0.26, h * 0.66);
      bodyPath.quadraticBezierTo(cx + w * 0.44, h * 0.70, cx + w * 0.48, h);
    }
    bodyPath.close();
    canvas.drawPath(bodyPath, p);

    // ── Outfit details ────────────────────────
    _drawOutfitDetail(canvas, p, w, h, cx);

    // ── Neck ──────────────────────────────────
    p.color = avatar.skinTone;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.635), width: w * 0.14, height: h * 0.10),
        const Radius.circular(6),
      ),
      p,
    );

    // ── Head (proper oval, not too round) ─────
    p.color = avatar.skinTone;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.37), width: w * 0.36, height: w * 0.44),
      p,
    );

    // ── Ears ──────────────────────────────────
    p.color = avatar.skinTone;
    // Left ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.195, h * 0.37), width: w * 0.065, height: w * 0.09),
      p,
    );
    // Right ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.195, h * 0.37), width: w * 0.065, height: w * 0.09),
      p,
    );
    // Inner ear
    p.color = avatar.skinTone
        .withRed((avatar.skinTone.red * 0.88).toInt())
        .withGreen((avatar.skinTone.green * 0.82).toInt());
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.195, h * 0.37), width: w * 0.035, height: w * 0.055),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.195, h * 0.37), width: w * 0.035, height: w * 0.055),
      p,
    );

    // ── Hair ──────────────────────────────────
    _drawHair(canvas, p, w, h, cx);

    // ── Eyebrows ──────────────────────────────
    final browP = Paint()
      ..color = avatar.hairColor
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Left brow (slight arch)
    final lBrow = Path();
    lBrow.moveTo(cx - w * 0.145, h * 0.298);
    lBrow.quadraticBezierTo(cx - w * 0.09, h * 0.282, cx - w * 0.04, h * 0.292);
    canvas.drawPath(lBrow, browP);
    // Right brow
    final rBrow = Path();
    rBrow.moveTo(cx + w * 0.04, h * 0.292);
    rBrow.quadraticBezierTo(cx + w * 0.09, h * 0.282, cx + w * 0.145, h * 0.298);
    canvas.drawPath(rBrow, browP);

    // ── Eyes ──────────────────────────────────
    // White of eye
    p.color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.092, h * 0.345), width: w * 0.085, height: w * 0.055),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.092, h * 0.345), width: w * 0.085, height: w * 0.055),
      p,
    );
    // Iris
    p.color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset(cx - w * 0.092, h * 0.347), w * 0.028, p);
    canvas.drawCircle(Offset(cx + w * 0.092, h * 0.347), w * 0.028, p);
    // Pupil
    p.color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - w * 0.092, h * 0.347), w * 0.016, p);
    canvas.drawCircle(Offset(cx + w * 0.092, h * 0.347), w * 0.016, p);
    // Eye shine
    p.color = Colors.white;
    canvas.drawCircle(Offset(cx - w * 0.082, h * 0.340), w * 0.007, p);
    canvas.drawCircle(Offset(cx + w * 0.102, h * 0.340), w * 0.007, p);
    // Upper eyelid line
    final lidP = Paint()
      ..color = const Color(0xFF2C1810).withOpacity(0.5)
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.092, h * 0.345), width: w * 0.085, height: w * 0.055),
      3.14, 3.14, false, lidP,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + w * 0.092, h * 0.345), width: w * 0.085, height: w * 0.055),
      3.14, 3.14, false, lidP,
    );

    // ── Eyelashes (female only) ───────────────
    if (avatar.isFemale) {
      final lashP = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 4; i++) {
        final lx = cx - w * 0.13 + i * w * 0.015;
        canvas.drawLine(Offset(lx, h * 0.328), Offset(lx - w * 0.005, h * 0.312), lashP);
        final rx = cx + w * 0.055 + i * w * 0.015;
        canvas.drawLine(Offset(rx, h * 0.328), Offset(rx + w * 0.002, h * 0.312), lashP);
      }
    }

    // ── Nose ──────────────────────────────────
    final noseP = Paint()
      ..color = avatar.skinTone
          .withRed((avatar.skinTone.red * 0.80).toInt())
          .withGreen((avatar.skinTone.green * 0.75).toInt())
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nosePath = Path();
    nosePath.moveTo(cx - w * 0.025, h * 0.395);
    nosePath.quadraticBezierTo(cx - w * 0.04, h * 0.42, cx, h * 0.425);
    nosePath.quadraticBezierTo(cx + w * 0.04, h * 0.42, cx + w * 0.025, h * 0.395);
    canvas.drawPath(nosePath, noseP);

    // ── Lips ──────────────────────────────────
    p.color = avatar.isFemale
        ? const Color(0xFFD4748F)
        : const Color(0xFFB57070);
    // Upper lip
    final upperLip = Path();
    upperLip.moveTo(cx - w * 0.075, h * 0.455);
    upperLip.quadraticBezierTo(cx - w * 0.03, h * 0.445, cx, h * 0.452);
    upperLip.quadraticBezierTo(cx + w * 0.03, h * 0.445, cx + w * 0.075, h * 0.455);
    upperLip.quadraticBezierTo(cx, h * 0.470, cx - w * 0.075, h * 0.455);
    canvas.drawPath(upperLip, p);
    // Lower lip (fuller)
    p.color = avatar.isFemale
        ? const Color(0xFFE88EA3)
        : const Color(0xFFC48080);
    final lowerLip = Path();
    lowerLip.moveTo(cx - w * 0.075, h * 0.455);
    lowerLip.quadraticBezierTo(cx, h * 0.492, cx + w * 0.075, h * 0.455);
    lowerLip.quadraticBezierTo(cx, h * 0.482, cx - w * 0.075, h * 0.455);
    canvas.drawPath(lowerLip, p);

    // ── Smile line ────────────────────────────
    final smileP = Paint()
      ..color = const Color(0xFFAD7070).withOpacity(0.6)
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Smile corners
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.065, h * 0.462), width: w * 0.04, height: w * 0.025),
      0, 1.8, false, smileP,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + w * 0.065, h * 0.462), width: w * 0.04, height: w * 0.025),
      1.35, 1.8, false, smileP,
    );

    // ── Blush cheeks ──────────────────────────
    p.color = const Color(0xFFFFB6B6).withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.155, h * 0.40), width: w * 0.095, height: w * 0.055),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.155, h * 0.40), width: w * 0.095, height: w * 0.055),
      p,
    );
  }

  void _drawHair(Canvas canvas, Paint p, double w, double h, double cx) {
    p.color = avatar.hairColor;

    if (avatar.isFemale) {
      switch (avatar.style) {
        case AvatarStyle.student:
        // Long straight, middle part
        // Back hair layer
          p.color = avatar.hairColor.withOpacity(0.85);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.30), width: w * 0.42, height: w * 0.30),
            p,
          );
          p.color = avatar.hairColor;
          // Side curtains
          final left = Path()
            ..moveTo(cx - w * 0.195, h * 0.28)
            ..quadraticBezierTo(cx - w * 0.24, h * 0.50, cx - w * 0.22, h * 0.72)
            ..lineTo(cx - w * 0.12, h * 0.72)
            ..quadraticBezierTo(cx - w * 0.15, h * 0.50, cx - w * 0.16, h * 0.28)
            ..close();
          canvas.drawPath(left, p);
          final right = Path()
            ..moveTo(cx + w * 0.195, h * 0.28)
            ..quadraticBezierTo(cx + w * 0.24, h * 0.50, cx + w * 0.22, h * 0.72)
            ..lineTo(cx + w * 0.12, h * 0.72)
            ..quadraticBezierTo(cx + w * 0.15, h * 0.50, cx + w * 0.16, h * 0.28)
            ..close();
          canvas.drawPath(right, p);
          // Top hair
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.245), width: w * 0.38, height: w * 0.18),
            p,
          );
          break;

        case AvatarStyle.casual:
        // Ponytail
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.265), width: w * 0.40, height: w * 0.22),
            p,
          );
          // Side hair
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.17, h * 0.35), width: w * 0.07, height: w * 0.14),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.17, h * 0.33), width: w * 0.06, height: w * 0.10),
            p,
          );
          // Ponytail
          final pony = Path()
            ..moveTo(cx + w * 0.10, h * 0.22)
            ..quadraticBezierTo(cx + w * 0.32, h * 0.18, cx + w * 0.30, h * 0.42)
            ..quadraticBezierTo(cx + w * 0.20, h * 0.42, cx + w * 0.10, h * 0.26)
            ..close();
          canvas.drawPath(pony, p);
          // Hair tie
          p.color = avatar.outfitColor;
          canvas.drawCircle(Offset(cx + w * 0.155, h * 0.265), w * 0.022, p);
          p.color = avatar.hairColor;
          break;

        case AvatarStyle.formal:
        // Bun
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.27), width: w * 0.38, height: w * 0.20),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.16, h * 0.34), width: w * 0.07, height: w * 0.12),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.16, h * 0.34), width: w * 0.07, height: w * 0.12),
            p,
          );
          // Bun circle on top
          canvas.drawCircle(Offset(cx, h * 0.195), w * 0.10, p);
          p.color = avatar.outfitColor.withOpacity(0.6);
          canvas.drawCircle(Offset(cx, h * 0.195), w * 0.06, p);
          p.color = avatar.hairColor;
          break;

        case AvatarStyle.cool:
        // Wavy bob
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.275), width: w * 0.42, height: w * 0.24),
            p,
          );
          // Wavy sides
          final wL = Path()
            ..moveTo(cx - w * 0.19, h * 0.28)
            ..cubicTo(cx - w * 0.26, h * 0.36, cx - w * 0.20, h * 0.44, cx - w * 0.22, h * 0.56)
            ..lineTo(cx - w * 0.12, h * 0.56)
            ..cubicTo(cx - w * 0.14, h * 0.44, cx - w * 0.16, h * 0.36, cx - w * 0.16, h * 0.28)
            ..close();
          canvas.drawPath(wL, p);
          final wR = Path()
            ..moveTo(cx + w * 0.19, h * 0.28)
            ..cubicTo(cx + w * 0.26, h * 0.36, cx + w * 0.20, h * 0.44, cx + w * 0.22, h * 0.56)
            ..lineTo(cx + w * 0.12, h * 0.56)
            ..cubicTo(cx + w * 0.14, h * 0.44, cx + w * 0.16, h * 0.36, cx + w * 0.16, h * 0.28)
            ..close();
          canvas.drawPath(wR, p);
          break;

        case AvatarStyle.sporty:
        // High ponytail
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.27), width: w * 0.38, height: w * 0.20),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.16, h * 0.34), width: w * 0.07, height: w * 0.12),
            p,
          );
          // High tail spraying up
          final ht = Path()
            ..moveTo(cx - w * 0.06, h * 0.205)
            ..quadraticBezierTo(cx + w * 0.10, h * 0.05, cx + w * 0.22, h * 0.12)
            ..quadraticBezierTo(cx + w * 0.15, h * 0.18, cx + w * 0.04, h * 0.22)
            ..close();
          canvas.drawPath(ht, p);
          p.color = avatar.outfitColor;
          canvas.drawCircle(Offset(cx, h * 0.215), w * 0.018, p);
          p.color = avatar.hairColor;
          break;

        case AvatarStyle.artistic:
        // Curly / voluminous
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.255), width: w * 0.46, height: w * 0.28),
            p,
          );
          // Curls on sides
          for (int i = 0; i < 3; i++) {
            canvas.drawCircle(
              Offset(cx - w * 0.20, h * 0.30 + i * h * 0.06),
              w * 0.055, p,
            );
            canvas.drawCircle(
              Offset(cx + w * 0.20, h * 0.30 + i * h * 0.06),
              w * 0.055, p,
            );
          }
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.215), width: w * 0.30, height: w * 0.14),
            p,
          );
          break;
      }
    } else {
      // Male hairstyles
      switch (avatar.style) {
        case AvatarStyle.student:
        // Neat short
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.265), width: w * 0.38, height: w * 0.18),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.17, h * 0.32), width: w * 0.06, height: w * 0.10),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.17, h * 0.32), width: w * 0.06, height: w * 0.10),
            p,
          );
          // Side part
          p.color = avatar.hairColor.withOpacity(0.4);
          canvas.drawLine(
            Offset(cx - w * 0.05, h * 0.22),
            Offset(cx - w * 0.12, h * 0.28),
            Paint()..color = p.color..strokeWidth = w * 0.015..strokeCap = StrokeCap.round,
          );
          p.color = avatar.hairColor;
          break;

        case AvatarStyle.casual:
        // Messy / textured
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.265), width: w * 0.38, height: w * 0.18),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.16, h * 0.32), width: w * 0.065, height: w * 0.11),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.16, h * 0.32), width: w * 0.065, height: w * 0.11),
            p,
          );
          // Tufts
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.08, h * 0.215), width: w * 0.09, height: w * 0.06),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.06, h * 0.205), width: w * 0.08, height: w * 0.05),
            p,
          );
          break;

        case AvatarStyle.formal:
        // Slicked back
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.255), width: w * 0.36, height: w * 0.14),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.16, h * 0.31), width: w * 0.055, height: w * 0.09),
            p,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.16, h * 0.31), width: w * 0.055, height: w * 0.09),
            p,
          );
          // Slick top
          final slick = Path()
            ..moveTo(cx - w * 0.17, h * 0.235)
            ..quadraticBezierTo(cx, h * 0.19, cx + w * 0.17, h * 0.235)
            ..quadraticBezierTo(cx, h * 0.24, cx - w * 0.17, h * 0.235)
            ..close();
          canvas.drawPath(slick, p);
          break;

        case AvatarStyle.cool:
        // Fade / undercut
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.26), width: w * 0.34, height: w * 0.15),
            p,
          );
          // Top quiff
          final quiff = Path()
            ..moveTo(cx - w * 0.14, h * 0.245)
            ..quadraticBezierTo(cx - w * 0.08, h * 0.17, cx, h * 0.175)
            ..quadraticBezierTo(cx + w * 0.08, h * 0.17, cx + w * 0.14, h * 0.245)
            ..quadraticBezierTo(cx, h * 0.23, cx - w * 0.14, h * 0.245)
            ..close();
          canvas.drawPath(quiff, p);
          break;

        case AvatarStyle.sporty:
        // Buzz cut / cap look
          p.color = avatar.outfitColor;
          // Cap
          final cap = Path()
            ..moveTo(cx - w * 0.20, h * 0.295)
            ..quadraticBezierTo(cx - w * 0.19, h * 0.22, cx, h * 0.20)
            ..quadraticBezierTo(cx + w * 0.19, h * 0.22, cx + w * 0.20, h * 0.295)
            ..close();
          canvas.drawPath(cap, p);
          // Brim
          p.color = avatar.outfitColor
              .withRed((avatar.outfitColor.red * 0.85).toInt());
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + w * 0.05, h * 0.295), width: w * 0.46, height: w * 0.075),
            p,
          );
          p.color = avatar.hairColor;
          // Visible hair on sides
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - w * 0.18, h * 0.33), width: w * 0.055, height: w * 0.07),
            p,
          );
          break;

        case AvatarStyle.artistic:
        // Long / flowing
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, h * 0.265), width: w * 0.40, height: w * 0.20),
            p,
          );
          final aL = Path()
            ..moveTo(cx - w * 0.19, h * 0.27)
            ..quadraticBezierTo(cx - w * 0.26, h * 0.42, cx - w * 0.24, h * 0.60)
            ..lineTo(cx - w * 0.14, h * 0.60)
            ..quadraticBezierTo(cx - w * 0.18, h * 0.42, cx - w * 0.16, h * 0.27)
            ..close();
          canvas.drawPath(aL, p);
          final aR = Path()
            ..moveTo(cx + w * 0.19, h * 0.27)
            ..quadraticBezierTo(cx + w * 0.26, h * 0.42, cx + w * 0.24, h * 0.60)
            ..lineTo(cx + w * 0.14, h * 0.60)
            ..quadraticBezierTo(cx + w * 0.18, h * 0.42, cx + w * 0.16, h * 0.27)
            ..close();
          canvas.drawPath(aR, p);
          break;
      }
    }
  }

  void _drawOutfitDetail(Canvas canvas, Paint p, double w, double h, double cx) {
    if (avatar.style == AvatarStyle.formal && !avatar.isFemale) {
      // White shirt collar
      p.color = Colors.white.withOpacity(0.8);
      final collar = Path()
        ..moveTo(cx - w * 0.10, h * 0.66)
        ..lineTo(cx, h * 0.73)
        ..lineTo(cx + w * 0.10, h * 0.66)
        ..lineTo(cx + w * 0.07, h)
        ..lineTo(cx - w * 0.07, h)
        ..close();
      canvas.drawPath(collar, p);
      // Tie
      p.color = const Color(0xFFAD1457);
      final tie = Path()
        ..moveTo(cx - w * 0.035, h * 0.665)
        ..lineTo(cx + w * 0.035, h * 0.665)
        ..lineTo(cx + w * 0.028, h * 0.82)
        ..lineTo(cx, h * 0.86)
        ..lineTo(cx - w * 0.028, h * 0.82)
        ..close();
      canvas.drawPath(tie, p);
    } else if (avatar.style == AvatarStyle.formal && avatar.isFemale) {
      // Blouse detail
      p.color = Colors.white.withOpacity(0.25);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.75), width: w * 0.12, height: w * 0.18),
        p,
      );
    } else if (avatar.style == AvatarStyle.sporty) {
      // Stripe
      p.color = Colors.white.withOpacity(0.2);
      canvas.drawRect(
        Rect.fromLTWH(cx - w * 0.03, h * 0.67, w * 0.06, h * 0.33),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(AvatarPainter old) => old.avatar.id != avatar.id;
}

// ── Avatar Widget ──────────────────────────────────────────────
class AvatarWidget extends StatelessWidget {
  final AvatarOption avatar;
  final double size;

  const AvatarWidget({super.key, required this.avatar, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: AvatarPainter(avatar)),
    );
  }
}

// ── Avatar Picker Sheet ────────────────────────────────────────
class AvatarPickerSheet extends StatefulWidget {
  final String selectedId;
  final void Function(AvatarOption) onSelected;

  const AvatarPickerSheet({super.key, required this.selectedId, required this.onSelected});

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Start on correct tab based on selected avatar
    final selAv = kAvatars.firstWhere(
          (a) => a.id == widget.selectedId,
      orElse: () => kAvatars.first,
    );
    if (!selAv.isFemale) _tab.index = 1;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2D0F1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Choose Your Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Tap any avatar to select it', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A0A12) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[500],
                indicator: BoxDecoration(
                  color: const Color(0xFFAD1457),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: const [
                  Tab(text: '👩 Female'),
                  Tab(text: '👨 Male'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildGrid(kAvatars.where((a) => a.isFemale).toList()),
                _buildGrid(kAvatars.where((a) => !a.isFemale).toList()),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildGrid(List<AvatarOption> list) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.80,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final av = list[i];
        final isSelected = widget.selectedId == av.id;
        return GestureDetector(
          onTap: () {
            widget.onSelected(av);
            Navigator.pop(ctx);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? av.outfitColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFAD1457) : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: const Color(0xFFAD1457).withOpacity(0.25), blurRadius: 10, spreadRadius: 1)
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarWidget(avatar: av, size: 68),
                const SizedBox(height: 4),
                Text(av.label, style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}