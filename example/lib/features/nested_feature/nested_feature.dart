import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'components/nested_component.dart';

final class NestedFeature extends ECSFeature {
  NestedFeature() {
    addEntity(NestedComponent());
  }
}