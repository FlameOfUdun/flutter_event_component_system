import 'package:analyzer/dart/element/element.dart';
import 'package:flutter_event_component_system_generator/src/models/feature_model.dart';

import 'entity_model.dart';

final class ManagerModel {
  final Map<VariableElement, FeatureModel> features = {};

  void addFeature(FeatureModel feature) {
    features[feature.element] = feature;
    feature.manager = this;
  }

  FeatureModel? getFeature(VariableElement element) => features[element];

  EntityModel? getEntity(VariableElement element) {
    for (final feature in features.values) {
      final entity = feature.getEntity(element);
      if (entity != null) return entity;
    }
    return null;
  }
}
