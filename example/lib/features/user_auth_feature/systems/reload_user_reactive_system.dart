part of '../user_auth_feature.dart';

final class ReloadUserReactiveSystem extends ReactiveSystem {
  ReloadUserReactiveSystem();

  @override
  Set<Type> get reactsTo {
    return {
      ReloadUserEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return {
      AuthStateComponent,
    };
  }

  @override
  void react() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('auth_state');
    final state = value == null ? AuthState.loggedOut : AuthState.values.byName(value);
    feature.getEntity<AuthStateComponent>().update(state);
  }
}
