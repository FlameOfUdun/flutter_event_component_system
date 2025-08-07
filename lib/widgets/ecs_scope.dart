part of '../flutter_event_component_system.dart';

final class ECSScope extends StatefulWidget {
  final Set<ECSFeature> Function(ECSManager manager) features;
  final Widget child;

  const ECSScope({
    super.key,
    required this.features,
    required this.child,
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

final class _ECSScopeState extends State<ECSScope> {
  final manager = ECSManager();

  Duration duration = Duration.zero;

  @override
  void initState() {
    final features = widget.features(manager);
    for (final feature in features) {
      manager.addFeature(feature);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.initialize();
    });

    WidgetsBinding.instance.addPersistentFrameCallback((Duration duration) {
      final elapsed = duration - this.duration;
      this.duration = duration;
      manager.execute(elapsed);
      
      manager.cleanup();
    });

    super.initState();
  }

  @override
  void dispose() {
    manager.teardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
