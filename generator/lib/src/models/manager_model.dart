import 'package:analyzer/dart/element/element.dart';
import 'package:flutter_event_component_system_generator/src/models/feature_model.dart';

import 'entity_model.dart';

final class ManagerModel {
  final Map<VariableElement, FeatureModel> features = {};

  void addFeature(FeatureModel feature) {
    features[feature.element] = feature;
    feature.manager = this;
  }

  FeatureModel? getFeature(VariableElement element) {
    final direct = features[element];
    if (direct != null) return direct;

    final path = element.firstFragment.libraryFragment?.source.fullName ?? '';
    final name = element.name ?? '';
    if (path.isEmpty || name.isEmpty) return null;

    for (final entry in features.entries) {
      final k = entry.key;
      if (k.name == name && k.firstFragment.libraryFragment?.source.fullName == path) {
        return entry.value;
      }
    }

    return null;
  }

  EntityModel? getEntity(VariableElement element) {
    for (final feature in features.values) {
      final entity = feature.getEntity(element);
      if (entity != null) return entity;
    }
    return null;
  }
}
