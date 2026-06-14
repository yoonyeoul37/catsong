import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StationLogo extends StatelessWidget {
  final String? logoUrl;
  final String  name;
  final double  size;
  final double? fontSize;

  const StationLogo({
    super.key,
    required this.logoUrl,
    required this.name,
    required this.size,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final color    = _colorFor(name);
    final fSize    = fontSize ?? size * 0.24;

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.network(
          logoUrl!,
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _Fallback(initials: initials, color: color,
                  size: size, fSize: fSize),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return _Fallback(initials: initials, color: color,
                size: size, fSize: fSize);
          },
        ),
      );
    }
    return _Fallback(
        initials: initials, color: color, size: size, fSize: fSize);
  }

  String _initials(String s) {
    final w = s.trim().split(' ');
    if (w.length >= 2) {
      return '${w[0][0]}${w[1][0]}'.toUpperCase();
    }
    return s.length >= 2
        ? s.substring(0, 2).toUpperCase()
        : s.toUpperCase();
  }

  Color _colorFor(String s) {
    const palette = [
      Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFFB71C1C),
      Color(0xFF1B5E20), Color(0xFF0277BD), Color(0xFF004D40),
      Color(0xFF37474F), Color(0xFF4A148C),
    ];
    final hash = s.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}

class _Fallback extends StatelessWidget {
  final String initials;
  final Color  color;
  final double size;
  final double fSize;
  const _Fallback({
    required this.initials,
    required this.color,
    required this.size,
    required this.fSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: fSize,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}