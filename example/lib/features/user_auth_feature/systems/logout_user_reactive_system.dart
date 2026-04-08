part of '../user_auth_feature.dart';

final class LogoutUserReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return {
      LogoutEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return {
      LogoutProcessComponent,
      AuthStateComponent,
    };
  }

  @override
  void react() {
    _performLogout().ignore();
  }

  Future<void> _performLogout() async {
    final process = getEntity<LogoutProcessComponent>();
    process.update(const LogoutProcess.running());
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedOut.name);
    await Future.delayed(const Duration(seconds: 2));
    process.update(const LogoutProcess.success());

    final state = getEntity<AuthStateComponent>();
    state.update(AuthState.loggedOut);
  }
}
