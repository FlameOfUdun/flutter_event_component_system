part of '../ecs_base.dart';

abstract class ECSWidget extends StatefulWidget {
  const ECSWidget({super.key});

  @override
  @visibleForTesting
  State<ECSWidget> createState() {
    return _ECSWidgetState();
  }

  Widget build(BuildContext context, ECSContext ecs);
}

final class _ECSWidgetState extends State<ECSWidget> {
  ECSContext? _ecs;

  @protected
  ECSContext get ecs {
    return _ecs ??= ECSContext(
      ECSScope.of(context),
      () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ecs.initialize();
    });
    super.initState();
  }

  @override
  void dispose() {
    ecs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, ecs);
  }
}

abstract class ECSStatefulWidget extends StatefulWidget {
  const ECSStatefulWidget({super.key});

  @override
  ECSState<ECSStatefulWidget> createState();
}

abstract class ECSState<TWidget extends ECSStatefulWidget> extends State<TWidget> {
  ECSContext? _ecs;

  @protected
  ECSContext get ecs {
    return _ecs ??= ECSContext(
      ECSScope.of(context),
      () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ecs.initialize();
    });
    super.initState();
  }

  @override
  void dispose() {
    ecs.dispose();
    super.dispose();
  }
}
