part of '../ecs_base.dart';

final class ECSScope extends StatefulWidget {
  final Set<ECSFeature> features;
  final Widget child;
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
    final scope = context.findAncestorStateOfType<_ECSScopeState>();
    if (scope == null) {
      throw FlutterError('ECSScope not found in context');
    }
    return scope.manager;
  }
}

final class _ECSScopeState extends State<ECSScope> with SingleTickerProviderStateMixin {
  final manager = ECSManager();

  Ticker? ticker;
  var duration = Duration.zero;

  @override
  void initState() {
    for (final feature in widget.features) {
      manager.addFeature(feature);
    }

    if (widget.useTicker) {
      buildTicker();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.initialize();
      ticker?.start();
    });

    super.initState();
  }

  void buildTicker() {
    ticker?.stop();
    ticker = createTicker((duration) {
      final elapsed = duration - this.duration;
      this.duration = duration;
      manager.execute(elapsed);
      manager.cleanup();
    });
  }

  @override
  void didUpdateWidget(covariant ECSScope oldWidget) {
    if (oldWidget.useTicker != widget.useTicker) {
      if (widget.useTicker) {
        buildTicker();
      } else {
        ticker?.stop();
        ticker = null;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    ticker?.dispose();
    manager.teardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
