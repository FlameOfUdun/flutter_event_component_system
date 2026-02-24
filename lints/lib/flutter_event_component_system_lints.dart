import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/rules/entity_must_be_in_interacts_with.dart';
import 'src/rules/event_data_only_in_react.dart';
import 'src/rules/no_event_data_across_async_gap.dart';

PluginBase createPlugin() => _EcsLintsPlugin();

class _EcsLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const EntityMustBeInInteractsWith(),
    const EventDataOnlyInReact(),
    const NoEventDataAcrossAsyncGap(),
  ];
}
