import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Builds an [ImageProvider] for a URL.
typedef NetworkImageProviderBuilder = ImageProvider Function(String url);

/// Optional override for how [PfNetworkImage] loads URLs.
///
/// The app uses the cached network loader by default. Previews and widget
/// tests can supply in-memory images here instead of hitting the network.
class NetworkImageScope extends InheritedWidget {
  const NetworkImageScope({
    required this.builder,
    required super.child,
    super.key,
  });

  final NetworkImageProviderBuilder builder;

  static NetworkImageProviderBuilder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NetworkImageScope>()?.builder;

  @override
  bool updateShouldNotify(NetworkImageScope oldWidget) =>
      builder != oldWidget.builder;
}

/// Cached network image with themed placeholder and error states.
class PfNetworkImage extends StatelessWidget {
  const PfNetworkImage({
    required this.url,
    required this.placeholder,
    this.error,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    super.key,
  });

  final String url;
  final Widget placeholder;
  final Widget? error;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final override = NetworkImageScope.maybeOf(context);
    if (override != null) {
      return Image(
        image: override(url),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => error ?? placeholder,
        frameBuilder: (context, child, frame, sync) =>
            frame == null && !sync ? placeholder : child,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: PfMotion.of(context, PfMotion.fast),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => error ?? placeholder,
    );
  }
}
