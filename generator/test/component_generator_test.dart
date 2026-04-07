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
  class FeatureDefinition {
    final String? description;
    const FeatureDefinition({this.description});
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
  group('ComponentGenerator', () {
    test('generates component class from const String variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSComponentDefinition() const String playerName = "";'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class PlayerNameComponent extends ECSComponent<String>'),
            contains('PlayerNameComponent([super.value = ""])'),
          ])),
        },
      );
    });

    test('generates component class from const int variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSComponentDefinition() const int health = 100;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class HealthComponent extends ECSComponent<int>'),
            contains('HealthComponent([super.value = 100])'),
          ])),
        },
      );
    });

    test('generates component class from const bool variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSComponentDefinition() const bool isActive = false;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class IsActiveComponent extends ECSComponent<bool>'),
            contains('IsActiveComponent([super.value = false])'),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSComponentDefinition(description: "Player score") const int score = 0;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// Player score'),
            contains('final class ScoreComponent'),
          ])),
        },
      );
    });
  });
}
