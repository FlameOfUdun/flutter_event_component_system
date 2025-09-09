part of '../ecs_base.dart';

final class ECSBuilder<TEntity extends ECSEntity> extends ECSWidget {
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
