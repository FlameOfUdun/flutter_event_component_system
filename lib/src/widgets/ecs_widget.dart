part of '../ecs_base.dart';

/// Base class for ECS widgets.
abstract class ECSWidget extends StatefulWidget {
  const ECSWidget({super.key});

  @override
  @visibleForTesting
  State<ECSWidget> createState() {
    return _ECSWidgetState();
  }

  Widget build(BuildContext context, ECSContext ecs);
}

final class _ECSWidgetState extends State<ECSWidget> with _ECSContextProvider<ECSWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context, ecs);
  }
}

/// Base class for stateful ECS widgets.
abstract class ECSStatefulWidget extends StatefulWidget {
  const ECSStatefulWidget({super.key});

  @override
  ECSState<ECSStatefulWidget> createState();
}

abstract class ECSState<TWidget extends ECSStatefulWidget> extends State<TWidget> with _ECSContextProvider {}

mixin _ECSContextProvider<T extends StatefulWidget> on State<T> {
  ECSContext? _ecs;

  @protected
  ECSContext get ecs {
    return _ecs ??= ECSContext(
      ECSScope.of(context),
      _rebuild,
    );
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ecs.initialize();
      }
    });
  }

  @override
  void dispose() {
    _ecs?.dispose();
    super.dispose();
  }
}

/// A widget that builds itself based on the ECS context.
final class ECSBuilder extends ECSWidget {
  /// The builder function that creates the widget tree based on the ECS context.
  final Widget Function(BuildContext context, ECSContext ecs) builder;

  const ECSBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    return builder(context, ecs);
  }
}
