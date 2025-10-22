part of '../ecs_base.dart';

/// A widget that provides an ECSManager scope to its descendants.
///
/// This widget manages the lifecycle of the ECS features in its scope,
/// including initialization, execution, cleanup, and teardown.
///
/// Features added to this scope will be automatically initialized when the
/// widget is inserted into the widget tree, and torn down when the widget is
/// removed from the tree.
///
/// After disposal, the features will also be removed from the ECS manager.
final class ECSScope extends StatefulWidget {
  /// Set of features to be managed by this ECS scope.
  final Set<ECSFeature> features;

  /// The child widget to be rendered within this ECS scope.
  final Widget child;

  /// Whether to use a ticker to drive the ECS execution loop.
  ///
  /// If true, a ticker will be created and started to call the execute and
  /// cleanup methods of the features at each tick. Default is false.
  final bool useTicker;

  const ECSScope({
    super.key,
    required this.features,
    required this.child,
    this.useTicker = false,
  });

  @override
  @protected
  State<ECSScope> createState() => _ECSScopeState();

  static ECSManager of(BuildContext context) {
    final manager = maybeOf(context);
    if (manager == null) {
      throw FlutterError('ECSScope not found in context');
    }
    return manager;
  }

  static ECSManager? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_ECSScopeState>()?.manager;
  }
}

final class _ECSScopeState extends State<ECSScope> with SingleTickerProviderStateMixin {
  ECSManager? manager;
  Ticker? ticker;
  Duration duration = Duration.zero;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final feature in widget.features) {
        feature.initialize();
      }

      if (widget.useTicker) {
        startTicker();
      }
    });

    super.initState();
  }

  Duration calculateElapsed(Duration duration) {
    final elapsed = duration - this.duration;
    this.duration = duration;
    return elapsed;
  }

  void startTicker() {
    ticker?.stop();
    ticker = createTicker((duration) {
      final elapsed = calculateElapsed(duration);

      for (final feature in widget.features) {
        feature.execute(elapsed);
      }

      for (final feature in widget.features) {
        feature.cleanup();
      }
    });
    ticker!.start();
  }

  void stopTicker() {
    ticker?.stop();
    ticker = null;
  }

  @override
  void didUpdateWidget(covariant ECSScope oldWidget) {
    if (oldWidget.useTicker != widget.useTicker) {
      if (widget.useTicker) {
        startTicker();
      } else {
        stopTicker();
      }
    }
    
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    stopTicker();

    for (final feature in widget.features) {
      feature.teardown();
    }

    for (final feature in widget.features) {
      manager!.removeFeature(feature);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (manager == null) {
      manager = ECSScope.maybeOf(context) ?? ECSManager();
      
      for (final feature in widget.features) {
        manager!.addFeature(feature);
      }
    }

    return widget.child;
  }
}
