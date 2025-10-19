import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import 'components/loading_error_component.dart';
import 'components/loading_state_component.dart';
import 'components/user_data_component.dart';
import 'events/load_user_event.dart';
import 'systems/load_user_data_reactive_system.dart';

class UserProfileFeature extends ECSFeature {
  UserProfileFeature() {
    // Register components
    addEntity(UserDataComponent());
    addEntity(LoadingStateComponent());
    addEntity(LoadingErrorComponent());

    // Register event
    addEntity(LoadUserEvent());

    // Register systems
    addSystem(LoadUserDataReactiveSystem());
  }
}
