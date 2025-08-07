part of '../flutter_event_component_system.dart';

final class ECSBuilder<TEntity extends ECSEntity> extends ECSWidget {
  final Widget Function(BuildContext context, ECSContext reference) builder;

  const ECSBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, ECSContext reference) {
    return builder(context, reference);
  }
}
