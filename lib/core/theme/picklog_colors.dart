import 'package:flutter/material.dart';

/// Semantic tone used by pills, badges, snackbars and state views.
///
/// [ember] is the brand accent. Use it for one element per composition.
enum PfTone { neutral, ember, connected, warning, error, info }

/// Pickforge brand colour tokens for Picklog.
///
/// Mirrors `packages/brand/src/tokens.css` in the Pickforge platform. Dark is
/// canonical. Read the active palette with [PicklogColors.of].
///
/// Raw status tokens ([connected], [warning], [error], [info]) are fills and
/// dots. Their `*Fg` pair is the text/icon colour that passes WCAG AA on the
/// theme surfaces (the raw tokens are too light on the cream light surface).
@immutable
class PicklogColors extends ThemeExtension<PicklogColors> {
  const PicklogColors({
    required this.brightness,
    required this.surface,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.textHi,
    required this.textMed,
    required this.textLow,
    required this.ember,
    required this.emberSoft,
    required this.emberDeep,
    required this.hairline,
    required this.hairlineStrong,
    required this.itemFill,
    required this.connected,
    required this.warning,
    required this.error,
    required this.info,
    required this.connectedFg,
    required this.warningFg,
    required this.errorFg,
    required this.infoFg,
    required this.emberFg,
  });

  /// Canonical dark palette.
  static const PicklogColors dark = PicklogColors(
    brightness: Brightness.dark,
    surface: Color(0xFF0A0A0B),
    surface1: Color(0xFF0F0F11),
    surface2: Color(0xFF141417),
    surface3: Color(0xFF1B1B1F),
    textHi: Color(0xFFF2F2F3),
    textMed: Color(0xFFA0A0A6),
    textLow: Color(0xFF6E6E75),
    ember: Color(0xFFFF7A1A),
    emberSoft: Color(0xFFFF9A4A),
    emberDeep: Color(0xFFCC5E0C),
    hairline: Color(0x14FFFFFF),
    hairlineStrong: Color(0x24FFFFFF),
    itemFill: Color(0x08FFFFFF),
    connected: Color(0xFF3DD68C),
    warning: Color(0xFFF2B53A),
    error: Color(0xFFFF6B5C),
    info: Color(0xFF7AA2FF),
    connectedFg: Color(0xFF3DD68C),
    warningFg: Color(0xFFF2B53A),
    errorFg: Color(0xFFFF6B5C),
    infoFg: Color(0xFF7AA2FF),
    emberFg: Color(0xFFFF7A1A),
  );

  /// Light palette: cream scaffold, white cards, deeper ember.
  static const PicklogColors light = PicklogColors(
    brightness: Brightness.light,
    surface: Color(0xFFFAFAF7),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F2EE),
    surface3: Color(0xFFE9E9E4),
    textHi: Color(0xFF17171A),
    textMed: Color(0xFF55555C),
    textLow: Color(0xFF6E6E75),
    ember: Color(0xFFE5610A),
    emberSoft: Color(0xFFF58220),
    emberDeep: Color(0xFFB14C00),
    hairline: Color(0x1A000000),
    hairlineStrong: Color(0x29000000),
    itemFill: Color(0x08000000),
    connected: Color(0xFF3DD68C),
    warning: Color(0xFF9A6700),
    error: Color(0xFFFF6B5C),
    info: Color(0xFF7AA2FF),
    connectedFg: Color(0xFF16774A),
    warningFg: Color(0xFF8A5C00),
    errorFg: Color(0xFFC0352A),
    infoFg: Color(0xFF2F5BD0),
    emberFg: Color(0xFFB14C00),
  );

  /// Text on photos and covers sits on a dark scrim in both themes.
  static const Color onImage = Color(0xFFF2F2F3);

  /// Dark scrim base for overlays on images (apply alpha at the call site).
  static const Color imageScrim = Color(0xFF0A0A0B);

  final Brightness brightness;
  final Color surface;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color textHi;
  final Color textMed;
  final Color textLow;
  final Color ember;
  final Color emberSoft;
  final Color emberDeep;
  final Color hairline;
  final Color hairlineStrong;
  final Color itemFill;
  final Color connected;
  final Color warning;
  final Color error;
  final Color info;
  final Color connectedFg;
  final Color warningFg;
  final Color errorFg;
  final Color infoFg;

  /// Ember as small text on the plain surfaces (deeper in light mode).
  final Color emberFg;

  bool get isDark => brightness == Brightness.dark;

  /// Text and icons on an ember fill use the canonical surface colour, never
  /// white. Light mode keeps the dark surface too: cream on the light ember is
  /// only 3.9:1, while #0A0A0B on it is 4.8:1 (AA).
  Color get onEmber => const Color(0xFF0A0A0B);

  /// Soft ember glow (`0 0 30 -8` at 25%).
  List<BoxShadow> get glowSoft => [
    BoxShadow(
      color: ember.withValues(alpha: isDark ? 0.25 : 0.3),
      blurRadius: 30,
      spreadRadius: -8,
    ),
  ];

  /// Regular ember glow (`0 0 60 -10` at 45%).
  List<BoxShadow> get glow => [
    BoxShadow(
      color: ember.withValues(alpha: 0.45),
      blurRadius: 60,
      spreadRadius: -10,
    ),
  ];

  /// Raised elevation (cards on hover, floating chrome).
  List<BoxShadow> get shadowRaised => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: isDark ? 0.4 : 0.08),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];

  /// Overlay elevation (sheets, dialogs, menus).
  List<BoxShadow> get shadowOverlay => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: isDark ? 0.6 : 0.14),
      blurRadius: 48,
      spreadRadius: -10,
      offset: const Offset(0, 16),
    ),
  ];

  /// Foreground (text/icon) colour for [tone] on the theme surfaces.
  Color toneForeground(PfTone tone) => switch (tone) {
    PfTone.neutral => textMed,
    PfTone.ember => emberFg,
    PfTone.connected => connectedFg,
    PfTone.warning => warningFg,
    PfTone.error => errorFg,
    PfTone.info => infoFg,
  };

  /// Raw fill colour for [tone] (dots, rings, tints).
  Color toneFill(PfTone tone) => switch (tone) {
    PfTone.neutral => textLow,
    PfTone.ember => ember,
    PfTone.connected => connected,
    PfTone.warning => warning,
    PfTone.error => error,
    PfTone.info => info,
  };

  /// Low-alpha tinted background for [tone] pills.
  Color toneBackground(PfTone tone) => tone == PfTone.neutral
      ? itemFill.withValues(alpha: isDark ? 0.06 : 0.05)
      : toneFill(tone).withValues(alpha: isDark ? 0.14 : 0.12);

  /// The active palette, falling back to [dark] outside a Picklog theme.
  static PicklogColors of(BuildContext context) =>
      Theme.of(context).extension<PicklogColors>() ??
      (Theme.of(context).brightness == Brightness.light ? light : dark);

  @override
  PicklogColors copyWith({Color? ember}) => PicklogColors(
    brightness: brightness,
    surface: surface,
    surface1: surface1,
    surface2: surface2,
    surface3: surface3,
    textHi: textHi,
    textMed: textMed,
    textLow: textLow,
    ember: ember ?? this.ember,
    emberSoft: emberSoft,
    emberDeep: emberDeep,
    hairline: hairline,
    hairlineStrong: hairlineStrong,
    itemFill: itemFill,
    connected: connected,
    warning: warning,
    error: error,
    info: info,
    connectedFg: connectedFg,
    warningFg: warningFg,
    errorFg: errorFg,
    infoFg: infoFg,
    emberFg: emberFg,
  );

  @override
  PicklogColors lerp(PicklogColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PicklogColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      surface: l(surface, other.surface),
      surface1: l(surface1, other.surface1),
      surface2: l(surface2, other.surface2),
      surface3: l(surface3, other.surface3),
      textHi: l(textHi, other.textHi),
      textMed: l(textMed, other.textMed),
      textLow: l(textLow, other.textLow),
      ember: l(ember, other.ember),
      emberSoft: l(emberSoft, other.emberSoft),
      emberDeep: l(emberDeep, other.emberDeep),
      hairline: l(hairline, other.hairline),
      hairlineStrong: l(hairlineStrong, other.hairlineStrong),
      itemFill: l(itemFill, other.itemFill),
      connected: l(connected, other.connected),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
      connectedFg: l(connectedFg, other.connectedFg),
      warningFg: l(warningFg, other.warningFg),
      errorFg: l(errorFg, other.errorFg),
      infoFg: l(infoFg, other.infoFg),
      emberFg: l(emberFg, other.emberFg),
    );
  }
}

/// Shorthand: `context.pfColors`.
extension PicklogColorsX on BuildContext {
  PicklogColors get pfColors => PicklogColors.of(this);
}
