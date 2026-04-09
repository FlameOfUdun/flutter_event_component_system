import 'component_generator_test.dart' as component;
import 'event_generator_test.dart' as event;
import 'dependency_generator_test.dart' as dependency;
import 'reactive_system_generator_test.dart' as reactive;
import 'initialize_system_generator_test.dart' as initialize;
import 'teardown_system_generator_test.dart' as teardown;
import 'cleanup_system_generator_test.dart' as cleanup;
import 'execute_system_generator_test.dart' as execute;
import 'feature_generator_test.dart' as feature;

void main() {
  component.main();
  event.main();
  dependency.main();
  reactive.main();
  initialize.main();
  teardown.main();
  cleanup.main();
  execute.main();
  feature.main();
}
