import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/consent/widgets/consent_banner.dart';

/// Shared frame for the sign-in and sign-up screens.
///
/// Phones get a full-bleed column. From 600 wide the content sits in a
/// centered card capped at 420. The brand mark, an eyebrow and the title
/// replace a generic app bar.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final isWide = MediaQuery.sizeOf(context).width >= PfBreakpoints.compact;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: colors.glowSoft,
            ),
            child: const BrandMark(size: 56),
          ),
        ),
        const SizedBox(height: PfSpace.xl),
        Eyebrow(eyebrow),
        const SizedBox(height: PfSpace.sm),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.displaySmall),
        ),
        const SizedBox(height: PfSpace.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge!.copyWith(color: colors.textMed),
        ),
        const SizedBox(height: PfSpace.xxl),
        ...children,
      ],
    );

    return Scaffold(
      // Keeps the form actions above the first-run consent banner.
      body: ConsentBannerPadding(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: PfSpace.xl,
                vertical: isWide ? PfSpace.xxxl : PfSpace.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: PfBreakpoints.auth + (isWide ? PfSpace.xxl * 2 : 0),
                ),
                child: isWide
                    ? Container(
                        padding: const EdgeInsets.all(PfSpace.xxl),
                        decoration: BoxDecoration(
                          color: colors.surface1,
                          borderRadius: PfRadius.xlAll,
                          border: Border.all(color: colors.hairline),
                          boxShadow: colors.shadowRaised,
                        ),
                        child: content,
                      )
                    : content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
