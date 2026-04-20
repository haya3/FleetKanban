import 'package:fluent_ui/fluent_ui.dart';
import 'package:system_theme/system_theme.dart';

/// Builds a FluentThemeData seeded from the OS accent colour. Typography is
/// overridden to prefer Yu Gothic UI so Japanese text renders with the
/// current Windows 11 glyph set, falling back to Segoe UI Variable / Segoe.
FluentThemeData buildFluentTheme(Brightness brightness) {
  final accent = SystemTheme.accentColor.accent;
  final swatch = AccentColor.swatch(<String, Color>{
    'darkest': accent.withValues(alpha: 1.0),
    'darker': accent,
    'dark': accent,
    'normal': accent,
    'light': accent,
    'lighter': accent,
    'lightest': accent.withValues(alpha: 0.6),
  });

  return FluentThemeData(
    brightness: brightness,
    accentColor: swatch,
    visualDensity: VisualDensity.standard,
    fontFamily: '"Yu Gothic UI", "Segoe UI Variable", "Segoe UI", sans-serif',
  );
}
