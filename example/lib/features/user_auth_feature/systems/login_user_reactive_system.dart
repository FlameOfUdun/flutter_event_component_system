part of '../user_auth_feature.dart';

final class LoginUserReactiveSystem extends ReactiveSystem {
  LoginUserReactiveSystem();

  @override
  Set<Type> get reactsTo {
    return {
      LoginEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return {
      LoginProcessComponent,
      AuthStateComponent,
    };
  }

  @override
  void react() async {
    feature.getEntity<LoginProcessComponent>().update(const LoginProcess.running());

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));

    feature.getEntity<LoginProcessComponent>().update(const LoginProcess.success('mock_token'));

    feature.getEntity<AuthStateComponent>().update(AuthState.loggedIn);
  }
}
