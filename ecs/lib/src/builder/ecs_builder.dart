library;

part 'entity_definition.dart';
part 'system_definition.dart';
part 'feature_definition.dart';

final class ECS {
  ECS._();

  static FeatureDefinition createFeature() {
    return FeatureDefinition._();
  }
}
