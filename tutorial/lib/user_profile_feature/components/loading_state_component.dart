import 'package:flutter_event_component_system/flutter_event_component_system.dart';

class LoadingStateComponent extends ECSComponent<LoadingState> {
  LoadingStateComponent() : super(LoadingState.idle);

  @override
  String buildDescriptor(LoadingState? value) {
    return 'LoadingState: ${value?.name}';
  }
}

enum LoadingState {
  idle,
  running,
  success,
  error,
}
