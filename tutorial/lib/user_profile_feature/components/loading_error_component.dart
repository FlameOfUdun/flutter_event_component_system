import 'package:flutter_event_component_system/flutter_event_component_system.dart';

class LoadingErrorComponent extends ECSComponent<String?> {
  LoadingErrorComponent() : super(null);

  @override
  String describe(String? value) {
    if (value == null || value.isEmpty) {
      return 'No Error';
    } else {
      return 'Error: $value';
    }
  }
}
