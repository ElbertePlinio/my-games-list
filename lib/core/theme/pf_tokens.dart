import 'package:flutter/widgets.dart';

/// Pickforge spacing scale (4/8/12/16/24/32/48).
abstract final class PfSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Pickforge corner radii.
abstract final class PfRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double card = 14;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Width breakpoints shared by the shell, grids and two-pane layouts.
abstract final class PfBreakpoints {
  /// Below this the shell uses a bottom navigation bar.
  static const double compact = 600;

  /// At or above this, detail screens switch to two panes.
  static const double twoPane = 840;

  /// At or above this, the rail extends and shows the wordmark.
  static const double expanded = 1200;

  /// Default max width for reading content on wide screens.
  static const double content = 1120;

  /// Max width for forms and settings.
  static const double narrow = 720;

  /// Max width for auth cards.
  static const double auth = 420;
}

/// Pickforge motion tokens.
///
/// Entrances use [forge]. No ease-in on entrances. Wrap every duration in
/// [PfMotion.of] so reduced motion collapses it to zero.
abstract final class PfMotion {
  static const Duration micro = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration reveal = Duration(milliseconds: 640);

  /// Dialog entrance: fade and rise 8px in 160ms.
  static const Duration dialog = Duration(milliseconds: 160);
  static const double dialogRise = 8;

  /// Main brand curve, `cubic-bezier(0.16, 1, 0.3, 1)`.
  static const Curve forge = Cubic(0.16, 1, 0.3, 1);

  /// Symmetric curve for state changes that go both ways.
  static const Curve curve = Cubic(0.65, 0, 0.35, 1);

  /// Gentle ease-out.
  static const Curve out = Cubic(0.33, 1, 0.68, 1);

  /// True when the platform asks to reduce or disable animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [duration], or zero under reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
