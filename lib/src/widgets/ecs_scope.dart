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
  ECSManager? manager;

  /// Ticker for driving the ECS execution loop.
  Ticker? ticker;

  /// Duration tracker for ticker elapsed time calculation.
  Duration duration = Duration.zero;

  /// Whether this scope is the primary ECS scope.
  bool isPrimary = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final feature in widget.features) {
        feature.initialize();
      }
      if (isPrimary) {
        if (manager!.hasExecuteOrCleanup) {
          startTicker();
        }
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
      for (final feature in widget.features) {
        feature.execute(elapsed);
      }
      for (final feature in widget.features) {
        feature.cleanup();
      }
    });
    ticker!.start();
  }

  @override
  void dispose() {
    ticker?.stop();
    for (final feature in widget.features) {
      feature.teardown();
    }
    for (final feature in widget.features) {
      feature.deactivate();
    }
    for (final feature in widget.features) {
      manager!.removeFeature(feature);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (manager == null) {
      final inherited = ECSScope.maybeOf(context);
      if (inherited == null) {
        manager = ECSManager();
        isPrimary = true;
        registerDevtools(manager!);
      } else {
        manager = inherited;
        isPrimary = false;
      }
      for (final feature in widget.features) {
        manager!.addFeature(feature);
      }
      for (final feature in widget.features) {
        feature.activate();
      }
    }

    return widget.child;
  }
}

var _devtoolsRegistered = false;

/// Registers DevTools extensions for ECS inspection.
void registerDevtools(ECSManager manager) {
  if (_devtoolsRegistered) return;
  developer.registerExtension('ext.ecs.requestManagerData', (method, parameters) async {
    final data = ECSManagerData.fromManager(manager).toJson();
    final encoded = jsonEncode(data);
    return developer.ServiceExtensionResponse.result(encoded);
  });
  _devtoolsRegistered = true;
}
