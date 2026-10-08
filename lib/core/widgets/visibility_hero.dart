import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Wraps a [Hero] with visibility awareness so that only heroes fully
/// visible inside every ancestor viewport participate in flight animations.
///
/// Uses [HeroMode] (not conditional Hero removal) so the Hero widget always
/// stays in the tree — only its `enabled` flag changes. This avoids the
/// widget-identity problems that occur when Hero is added/removed dynamically.
///
/// Subscribes to the [ScrollPosition] of **every ancestor scrollable** so
/// visibility is re-evaluated on every scroll event at any nesting level.
/// Uses [RenderBox.localToGlobal] for the check — synchronous, correct for
/// any combination of vertical/horizontal/carousel scrollables.
///
/// The check is always deferred to [addPostFrameCallback] because
/// [ScrollPosition.notifyListeners] fires during the `transientCallbacks`
/// phase, **before** layout runs for the new scroll offset. Deferring ensures
/// [localToGlobal] reflects the current frame's real positions.
///
/// Also re-evaluates on [didChangeMetrics] so a viewport/window resize — common
/// on web, where no [ScrollPosition] notification fires — cannot leave the
/// visibility flag stale.
///
/// Intended for **source** heroes in scrollable lists. Do NOT use on the
/// destination hero (e.g. the cover on a details screen): the destination
/// widget is off-screen while sliding in, which would disable it before the
/// flight can land.
class VisibilityHero extends StatefulWidget {
  const VisibilityHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  State<VisibilityHero> createState() => _VisibilityHeroState();
}

class _VisibilityHeroState extends State<VisibilityHero>
    with WidgetsBindingObserver {
  final List<ScrollPosition> _subscriptions = [];

  // Start enabled — hero is active before the first frame is measured.
  bool _isVisible = true;

  // Deduplication flag: ensures at most one post-frame check per frame,
  // even if multiple ancestor scroll positions fire in the same frame.
  bool _pendingVisibilityCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unsubscribe();
    _subscribe();
    _scheduleVisibilityCheck();
  }

  /// Fires on viewport/window resize. On web a resize can move this item in or
  /// out of the viewport without any scroll, so re-check visibility here.
  @override
  void didChangeMetrics() {
    _scheduleVisibilityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribe();
    super.dispose();
  }

  /// Walks up the widget tree subscribing to every ancestor [ScrollPosition].
  ///
  /// [Scrollable.maybeOf(scrollable.context)] jumps from the inner scrollable
  /// to the next ancestor scrollable, covering all nesting levels (e.g. a
  /// horizontal ListView inside a vertical SingleChildScrollView).
  void _subscribe() {
    BuildContext? ctx = context;
    while (ctx != null) {
      final scrollable = Scrollable.maybeOf(ctx);
      if (scrollable == null) break;
      scrollable.position.addListener(_scheduleVisibilityCheck);
      _subscriptions.add(scrollable.position);
      // Move up to the Scrollable widget's own context so the next iteration
      // finds the parent scrollable, not this one again.
      ctx = scrollable.context;
    }
  }

  void _unsubscribe() {
    for (final pos in _subscriptions) {
      pos.removeListener(_scheduleVisibilityCheck);
    }
    _subscriptions.clear();
  }

  /// Queues a single [_updateVisibility] call for the end of the current frame.
  ///
  /// Scroll listeners fire before layout, so [localToGlobal] would return
  /// stale positions if called immediately. Deferring to [addPostFrameCallback]
  /// ensures layout has already applied the new scroll offset.
  void _scheduleVisibilityCheck() {
    if (_pendingVisibilityCheck) return;
    _pendingVisibilityCheck = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingVisibilityCheck = false;
      _updateVisibility();
    });
  }

  void _updateVisibility() {
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;

    late final Offset offset;
    try {
      offset = box.localToGlobal(Offset.zero);
    } catch (_) {
      // Widget is not yet part of the composited layer tree.
      return;
    }

    final itemRect = offset & box.size;

    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return;
    final screenSize = view.physicalSize / view.devicePixelRatio;
    var visibleRect = Offset.zero & screenSize;

    // Clip to every ancestor scrollable's viewport. The viewport excludes the
    // app bar and navigation bar, so a tile partly hidden under either never
    // starts a flight that would paint over that chrome.
    for (final position in _subscriptions) {
      final viewportBox = position.context.notificationContext
          ?.findRenderObject();
      if (viewportBox is! RenderBox || !viewportBox.hasSize) continue;
      try {
        final viewportRect =
            viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
        visibleRect = visibleRect.intersect(viewportRect);
      } catch (_) {
        return;
      }
    }

    // Allow sub-pixel rounding at the edges.
    final visible =
        !visibleRect.isEmpty &&
        visibleRect.inflate(1).contains(itemRect.topLeft) &&
        visibleRect.inflate(1).contains(itemRect.bottomRight);
    if (visible != _isVisible) {
      setState(() => _isVisible = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: _isVisible,
      child: Hero(tag: widget.tag, child: widget.child),
    );
  }
}
