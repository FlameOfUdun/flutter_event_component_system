import 'component_generator_test.dart' as component_generator_test;
import 'event_generator_test.dart' as event_generator_test;
import 'data_event_generator_test.dart' as data_event_generator_test;
import 'dependency_generator_test.dart' as dependency_generator_test;
import 'reactive_system_generator_test.dart' as reactive_system_generator_test;
import 'initialize_system_generator_test.dart' as initialize_system_generator_test;
import 'teardown_system_generator_test.dart' as teardown_system_generator_test;
import 'cleanup_system_generator_test.dart' as cleanup_system_generator_test;
import 'execute_system_generator_test.dart' as execute_system_generator_test;
import 'feature_generator_test.dart' as feature_generator_test;

void main() {
  component_generator_test.main();
  event_generator_test.main();
  data_event_generator_test.main();
  dependency_generator_test.main();
  reactive_system_generator_test.main();
  initialize_system_generator_test.main();
  teardown_system_generator_test.main();
  cleanup_system_generator_test.main();
  execute_system_generator_test.main();
  feature_generator_test.main();
}
