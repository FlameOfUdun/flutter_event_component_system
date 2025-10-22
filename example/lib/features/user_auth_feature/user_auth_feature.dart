import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'components/auth_state_component.dart';
part 'components/login_credentials_component.dart';
part 'components/login_process_component.dart';
part 'components/logout_process_component.dart';

part 'events/logout_event.dart';
part 'events/login_event.dart';
part 'events/reload_user_event.dart';

part 'systems/reload_user_reactive_system.dart';
part 'systems/logout_user_reactive_system.dart';
part 'systems/login_user_reactive_system.dart';

final class UserAuthFeature extends ECSFeature {
  UserAuthFeature() {
    // Components
    addEntity(AuthStateComponent());
    addEntity(LoginCredentialsComponent());
    addEntity(LoginProcessComponent());
    addEntity(LogoutProcessComponent());

    // Events
    addEntity(LoginEvent());
    addEntity(LogoutEvent());
    addEntity(ReloadUserEvent());

    // Systems
    addSystem(ReloadUserReactiveSystem());
    addSystem(LogoutUserReactiveSystem());
    addSystem(LoginUserReactiveSystem());
  }
}
