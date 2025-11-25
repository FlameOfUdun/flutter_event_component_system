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

  const ECSScope({
    super.key,
    required this.features,
    required this.child,
  });

  @override
  @protected
  State<ECSScope> createState() => _ECSScopeState();

  /// Gets the ECS manager from the nearest ECSScope ancestor.
  static ECSManager of(BuildContext context) {
    final manager = maybeOf(context);
    if (manager == null) {
      throw FlutterError('ECSScope not found in context');
    }
    return manager;
  }

  /// Gets the ECS manager from the nearest ECSScope ancestor, or null if not found.
  static ECSManager? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_ECSScopeState>()?.manager;
  }
}

final class _ECSScopeState extends State<ECSScope> with SingleTickerProviderStateMixin {
  /// The ECS manager for this scope.
  final manager = ECSManager();

  /// Ticker for driving the ECS execution loop.
  Ticker? ticker;

  /// Duration tracker for ticker elapsed time calculation.
  Duration duration = Duration.zero;

  @override
  void initState() {
    for (final feature in widget.features) {
      manager.addFeature(feature);
    }
    manager.activate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.initialize();
      if (manager.hasExecuteOrCleanupSystems) {
        startTicker();
      }
    });
    super.initState();
  }

  /// Calculates the elapsed duration since the last call.
  Duration calculateElapsed(Duration duration) {
    final elapsed = duration - this.duration;
    this.duration = duration;
    return elapsed;
  }

  /// Starts the ticker to drive the ECS execution loop.
  void startTicker() {
    ticker = createTicker((duration) {
      final elapsed = calculateElapsed(duration);
      manager.execute(elapsed);
      manager.cleanup();
    });
    ticker!.start();
  }

  @override
  void dispose() {
    ticker?.stop();
    manager.teardown();
    manager.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
