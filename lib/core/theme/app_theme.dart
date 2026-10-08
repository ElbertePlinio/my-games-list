import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_page_transitions.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Builds the Pickforge light and dark [ThemeData] for Picklog.
///
/// The [ColorScheme] maps the brand tokens directly (no seed). Every common
/// component gets a theme so feature code rarely needs local styling. Themes
/// are built once at startup and cached by the caller.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() => build(PicklogColors.light);

  static ThemeData dark() => build(PicklogColors.dark);

  /// [ColorScheme] built from the brand tokens.
  static ColorScheme colorScheme(PicklogColors c) {
    Color tint(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), c.surface2);
    return ColorScheme(
      brightness: c.brightness,
      primary: c.ember,
      onPrimary: c.onEmber,
      primaryContainer: tint(c.ember, c.isDark ? 0.16 : 0.14),
      onPrimaryContainer: c.isDark ? c.emberSoft : c.emberDeep,
      primaryFixed: c.ember,
      primaryFixedDim: c.emberDeep,
      onPrimaryFixed: c.onEmber,
      secondary: c.textMed,
      onSecondary: c.surface,
      secondaryContainer: c.surface3,
      onSecondaryContainer: c.textHi,
      tertiary: c.infoFg,
      onTertiary: c.surface,
      tertiaryContainer: tint(c.info, 0.16),
      onTertiaryContainer: c.infoFg,
      error: c.errorFg,
      onError: c.surface,
      errorContainer: tint(c.error, c.isDark ? 0.16 : 0.12),
      onErrorContainer: c.errorFg,
      surface: c.surface,
      onSurface: c.textHi,
      onSurfaceVariant: c.textMed,
      surfaceDim: c.surface,
      surfaceBright: c.surface3,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface1,
      surfaceContainer: c.surface1,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface3,
      outline: c.textLow,
      outlineVariant: c.hairlineStrong,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.textHi,
      onInverseSurface: c.surface,
      inversePrimary: c.isDark ? c.emberDeep : c.emberSoft,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData build(PicklogColors c) {
    final text = PfTypography.textTheme(c);
    final parts = _ComponentThemes(c, text);

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: colorScheme(c),
      fontFamily: PfTypography.sans,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      dividerColor: c.hairline,
      hoverColor: c.itemFill,
      highlightColor: Colors.transparent,
      focusColor: c.ember.withValues(alpha: 0.16),
      extensions: [c],
      iconTheme: IconThemeData(color: c.textHi, size: 22),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PfPageTransitionsBuilder(),
          TargetPlatform.iOS: PfPageTransitionsBuilder(),
          TargetPlatform.macOS: PfPageTransitionsBuilder(),
          TargetPlatform.linux: PfPageTransitionsBuilder(),
          TargetPlatform.windows: PfPageTransitionsBuilder(),
          TargetPlatform.fuchsia: PfPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      appBarTheme: parts.appBar,
      navigationBarTheme: parts.navigationBar,
      navigationRailTheme: parts.navigationRail,
      cardTheme: parts.card,
      chipTheme: parts.chip,
      filledButtonTheme: parts.filledButton,
      outlinedButtonTheme: parts.outlinedButton,
      textButtonTheme: parts.textButton,
      elevatedButtonTheme: parts.elevatedButton,
      iconButtonTheme: parts.iconButton,
      floatingActionButtonTheme: parts.floatingActionButton,
      inputDecorationTheme: parts.inputDecoration,
      textSelectionTheme: parts.textSelection,
      bottomSheetTheme: parts.bottomSheet,
      dialogTheme: parts.dialog,
      snackBarTheme: parts.snackBar,
      sliderTheme: parts.slider,
      listTileTheme: parts.listTile,
      switchTheme: parts.switches,
      checkboxTheme: parts.checkbox,
      radioTheme: parts.radio,
      segmentedButtonTheme: parts.segmentedButton,
      progressIndicatorTheme: parts.progressIndicator,
      tooltipTheme: parts.tooltip,
      badgeTheme: parts.badge,
      expansionTileTheme: parts.expansionTile,
      datePickerTheme: parts.datePicker,
      popupMenuTheme: parts.popupMenu,
      dropdownMenuTheme: parts.dropdownMenu,
    );
  }
}

/// Component themes for one palette, split out of [AppTheme.build].
final class _ComponentThemes {
  const _ComponentThemes(this.c, this.text);

  final PicklogColors c;
  final TextTheme text;

  static const pill = StadiumBorder();

  // Pill buttons: sm 36 / md 44 / lg 56. Medium is the default size.
  static const buttonSize = Size(64, 44);
  static const buttonPadding = EdgeInsets.symmetric(horizontal: 20);

  BorderSide get hairlineSide => BorderSide(color: c.hairline);

  TextStyle get buttonText =>
      text.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: PfRadius.mdAll,
        borderSide: BorderSide(color: color, width: width),
      );

  AppBarTheme get appBar => AppBarTheme(
    backgroundColor: c.surface,
    surfaceTintColor: Colors.transparent,
    foregroundColor: c.textHi,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: PfSpace.lg,
    titleTextStyle: text.headlineSmall,
    iconTheme: IconThemeData(color: c.textHi),
    actionsIconTheme: IconThemeData(color: c.textHi),
  );

  NavigationBarThemeData get navigationBar => NavigationBarThemeData(
    backgroundColor: c.surface1,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 68,
    indicatorColor: c.ember.withValues(alpha: c.isDark ? 0.16 : 0.14),
    indicatorShape: pill,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: 22,
        color: states.contains(WidgetState.selected) ? c.emberFg : c.textMed,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => text.labelSmall!.copyWith(
        color: states.contains(WidgetState.selected) ? c.textHi : c.textMed,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w500,
      ),
    ),
  );

  NavigationRailThemeData get navigationRail => NavigationRailThemeData(
    backgroundColor: c.surface1,
    elevation: 0,
    indicatorColor: c.ember.withValues(alpha: c.isDark ? 0.16 : 0.14),
    indicatorShape: pill,
    useIndicator: true,
    selectedIconTheme: IconThemeData(color: c.emberFg, size: 22),
    unselectedIconTheme: IconThemeData(color: c.textMed, size: 22),
    selectedLabelTextStyle: text.labelMedium!.copyWith(
      color: c.textHi,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelTextStyle: text.labelMedium!.copyWith(color: c.textMed),
  );

  CardThemeData get card => CardThemeData(
    color: c.surface1,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.cardAll,
      side: hairlineSide,
    ),
  );

  ChipThemeData get chip => ChipThemeData(
    backgroundColor: c.surface2,
    selectedColor: c.ember.withValues(alpha: c.isDark ? 0.16 : 0.14),
    disabledColor: c.itemFill,
    checkmarkColor: c.emberFg,
    deleteIconColor: c.textMed,
    labelStyle: text.labelMedium!.copyWith(color: c.textHi),
    secondaryLabelStyle: text.labelMedium!.copyWith(
      color: c.textHi,
      fontWeight: FontWeight.w600,
    ),
    side: hairlineSide,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: PfSpace.sm),
    iconTheme: IconThemeData(color: c.textMed, size: 16),
    showCheckmark: false,
  );

  FilledButtonThemeData get filledButton => FilledButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(buttonSize),
      padding: const WidgetStatePropertyAll(buttonPadding),
      shape: const WidgetStatePropertyAll(pill),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(buttonText),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return c.surface3;
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return c.emberSoft;
        }
        return c.ember;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? c.textLow : c.onEmber,
      ),
      overlayColor: WidgetStatePropertyAll(c.onEmber.withValues(alpha: 0.08)),
    ),
  );

  OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(buttonSize),
      padding: const WidgetStatePropertyAll(buttonPadding),
      shape: const WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(buttonText),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ? c.surface2 : c.surface1,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? c.textLow : c.textHi,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color:
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)
              ? c.ember.withValues(alpha: 0.5)
              : c.hairlineStrong,
        ),
      ),
      overlayColor: WidgetStatePropertyAll(c.itemFill),
    ),
  );

  TextButtonThemeData get textButton => TextButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: PfSpace.md),
      ),
      shape: const WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(
        text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? c.textLow : c.textHi,
      ),
      overlayColor: WidgetStatePropertyAll(c.itemFill),
    ),
  );

  ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(buttonSize),
      padding: const WidgetStatePropertyAll(buttonPadding),
      shape: const WidgetStatePropertyAll(pill),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(buttonText),
      backgroundColor: WidgetStatePropertyAll(c.surface2),
      foregroundColor: WidgetStatePropertyAll(c.textHi),
    ),
  );

  IconButtonThemeData get iconButton => IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? c.textLow : c.textHi,
      ),
      overlayColor: WidgetStatePropertyAll(c.itemFill),
    ),
  );

  FloatingActionButtonThemeData get floatingActionButton =>
      FloatingActionButtonThemeData(
        backgroundColor: c.ember,
        foregroundColor: c.onEmber,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: pill,
        extendedTextStyle: buttonText,
      );

  InputDecorationTheme get inputDecoration => InputDecorationTheme(
    filled: true,
    fillColor: c.surface2,
    hoverColor: c.itemFill,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PfSpace.lg,
      vertical: PfSpace.md + 2,
    ),
    hintStyle: text.bodyLarge!.copyWith(color: c.textLow),
    labelStyle: text.bodyMedium!.copyWith(color: c.textMed),
    floatingLabelStyle: text.bodyMedium!.copyWith(color: c.textHi),
    helperStyle: text.bodySmall,
    errorStyle: text.bodySmall!.copyWith(color: c.errorFg),
    prefixIconColor: c.textMed,
    suffixIconColor: c.textMed,
    border: inputBorder(c.hairline),
    enabledBorder: inputBorder(c.hairline),
    focusedBorder: inputBorder(c.ember, 1.5),
    errorBorder: inputBorder(c.errorFg),
    focusedErrorBorder: inputBorder(c.errorFg, 1.5),
    disabledBorder: inputBorder(c.hairline),
  );

  TextSelectionThemeData get textSelection => TextSelectionThemeData(
    cursorColor: c.ember,
    selectionColor: c.ember.withValues(alpha: 0.3),
    selectionHandleColor: c.ember,
  );

  BottomSheetThemeData get bottomSheet => BottomSheetThemeData(
    backgroundColor: c.surface1,
    modalBackgroundColor: c.surface1,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: c.hairlineStrong,
    dragHandleSize: const Size(36, 4),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PfRadius.xl),
      ),
      side: hairlineSide,
    ),
    constraints: const BoxConstraints(maxWidth: 640),
  );

  DialogThemeData get dialog => DialogThemeData(
    backgroundColor: c.surface1,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.xlAll,
      side: BorderSide(color: c.hairlineStrong),
    ),
    titleTextStyle: text.headlineSmall,
    contentTextStyle: text.bodyLarge!.copyWith(color: c.textMed),
  );

  SnackBarThemeData get snackBar => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: c.isDark ? c.surface3 : c.textHi,
    contentTextStyle: text.bodyMedium!.copyWith(
      color: c.isDark ? c.textHi : c.surface,
    ),
    actionTextColor: c.emberSoft,
    elevation: 0,
    insetPadding: const EdgeInsets.all(PfSpace.lg),
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.mdAll,
      side: BorderSide(color: c.hairlineStrong),
    ),
  );

  SliderThemeData get slider => SliderThemeData(
    activeTrackColor: c.ember,
    inactiveTrackColor: c.surface3,
    thumbColor: c.ember,
    overlayColor: c.ember.withValues(alpha: 0.14),
    valueIndicatorColor: c.textHi,
    valueIndicatorTextStyle: text.labelMedium!.copyWith(color: c.surface),
    trackHeight: 4,
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
  );

  ListTileThemeData get listTile => ListTileThemeData(
    iconColor: c.textMed,
    titleTextStyle: text.titleMedium,
    subtitleTextStyle: text.bodySmall,
    contentPadding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
    minVerticalPadding: PfSpace.md,
    shape: const RoundedRectangleBorder(borderRadius: PfRadius.mdAll),
    selectedColor: c.emberFg,
  );

  SwitchThemeData get switches => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? c.onEmber : c.textMed,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? c.ember : c.surface3,
    ),
    trackOutlineColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.transparent
          : c.hairlineStrong,
    ),
  );

  CheckboxThemeData get checkbox => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? c.ember : Colors.transparent,
    ),
    checkColor: WidgetStatePropertyAll(c.onEmber),
    side: BorderSide(color: c.textLow, width: 1.5),
    shape: const RoundedRectangleBorder(borderRadius: PfRadius.smAll),
  );

  RadioThemeData get radio => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? c.ember : c.textLow,
    ),
  );

  SegmentedButtonThemeData get segmentedButton => SegmentedButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
      shape: const WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(
        text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: c.hairlineStrong)),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.ember.withValues(alpha: c.isDark ? 0.16 : 0.14)
            : c.surface1,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.textHi : c.textMed,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.emberFg : c.textMed,
      ),
    ),
  );

  ProgressIndicatorThemeData get progressIndicator =>
      ProgressIndicatorThemeData(
        color: c.ember,
        linearTrackColor: c.surface3,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: c.surface2,
      );

  TooltipThemeData get tooltip => TooltipThemeData(
    decoration: BoxDecoration(
      color: c.isDark ? c.surface3 : c.textHi,
      borderRadius: PfRadius.smAll,
      border: Border.all(color: c.hairlineStrong),
    ),
    textStyle: text.labelSmall!.copyWith(
      color: c.isDark ? c.textHi : c.surface,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: PfSpace.sm,
      vertical: PfSpace.xs + 2,
    ),
    waitDuration: PfMotion.slow,
  );

  BadgeThemeData get badge => BadgeThemeData(
    backgroundColor: c.ember,
    textColor: c.onEmber,
    textStyle: PfTypography.monoStyle(c.onEmber, size: 10),
  );

  ExpansionTileThemeData get expansionTile => ExpansionTileThemeData(
    iconColor: c.textMed,
    collapsedIconColor: c.textMed,
    textColor: c.textHi,
    collapsedTextColor: c.textHi,
    shape: const Border(),
    collapsedShape: const Border(),
    tilePadding: EdgeInsets.zero,
  );

  DatePickerThemeData get datePicker => DatePickerThemeData(
    backgroundColor: c.surface1,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: c.surface2,
    headerForegroundColor: c.textHi,
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.xlAll,
      side: BorderSide(color: c.hairlineStrong),
    ),
  );

  PopupMenuThemeData get popupMenu => PopupMenuThemeData(
    color: c.surface2,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.mdAll,
      side: BorderSide(color: c.hairlineStrong),
    ),
    textStyle: text.bodyMedium,
  );

  DropdownMenuThemeData get dropdownMenu => DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(c.surface2),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: PfRadius.mdAll,
          side: BorderSide(color: c.hairlineStrong),
        ),
      ),
    ),
  );
}
