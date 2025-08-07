part of '../user_auth_feature.dart';

final class LogoutUserReactiveSystem extends ReactiveSystem {
  final ECSManager manager;

  LogoutUserReactiveSystem(this.manager);

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
  void react() async {
    manager.getEntity<LogoutProcessComponent>().update(const LogoutProcess.running());

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_state');
    await Future.delayed(const Duration(seconds: 2));

    manager.getEntity<LogoutProcessComponent>().update(const LogoutProcess.success());

    manager.getEntity<AuthStateComponent>().update(AuthState.loggedOut);
  }
}
