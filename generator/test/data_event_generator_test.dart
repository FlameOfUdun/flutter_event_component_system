import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey = 'flutter_event_component_system_generator|lib/input.ecs.dart';

const _annotationAsset = 'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';

const _annotationSource = '''
  class ECSComponentDefinition {
    final String? description;
    const ECSComponentDefinition({this.description});
  }
  class ECSEventDefinition {
    final String? description;
    const ECSEventDefinition({this.description});
  }
  class ECSDataEventDefinition {
    final String? description;
    const ECSDataEventDefinition({this.description});
  }
  class ECSReactiveSystemDefinition {
    final String? description;
    final Set<Object> reactsTo;
    final Set<Object> interactsWith;
    final bool Function(dynamic)? reactsIf;
    const ECSReactiveSystemDefinition({
      this.description,
      required this.reactsTo,
      this.interactsWith = const {},
      this.reactsIf,
    });
  }
  class ECSFeatureDefinition {
    final String? description;
    const ECSFeatureDefinition({this.description});
  }
  class ECSDependencyDefinition {
    final String? description;
    const ECSDependencyDefinition({this.description});
  }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.dart';
        $body
      ''',
  };
}

void main() {
  group('DataEventGenerator', () {
    test('generates data event with trigger override for int', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSDataEventDefinition() const int addHealth = 10;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class AddHealthEvent extends ECSDataEvent<int>'),
            contains('void trigger([int data = 10]) => super.trigger(data);'),
          ])),
        },
      );
    });

    test('generates data event with trigger override for String', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSDataEventDefinition() const String setName = "player";'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class SetNameEvent extends ECSDataEvent<String>'),
            contains('void trigger([String data = "player"]) => super.trigger(data);'),
          ])),
        },
      );
    });
  });
}
