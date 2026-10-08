import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Centers [child] and caps its width so content stays readable on wide
/// screens. Below [maxWidth] it simply fills the available width.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    required this.child,
    this.maxWidth = PfBreakpoints.content,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// [Scaffold] whose body is width-capped by [MaxWidthBox].
///
/// Use it for list and form screens. Screens with full-bleed media (home
/// carousels, game details header) cap their own content instead.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.maxContentWidth = PfBreakpoints.content,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: MaxWidthBox(maxWidth: maxContentWidth, child: body),
    );
  }
}
