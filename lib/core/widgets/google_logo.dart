import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The official four-color Google "G" mark, rendered from the bundled SVG so it
/// matches Google's branding exactly on the "Sign in with Google" button.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/google_g.svg',
      width: size,
      height: size,
    );
  }
}
