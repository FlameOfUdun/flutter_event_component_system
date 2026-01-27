part of '../user_auth_feature.dart';

final class LoginUserReactiveSystem extends ReactiveSystem {
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
  void react() {
    final event = getEntity<LoginEvent>();
    _performLogin(event.data!).ignore();
  }

  Future<void> _performLogin(LoginCredentials credentials) async {
    final process = getEntity<LoginProcessComponent>();
    process.update(const LoginProcess.running());
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));
    process.update(const LoginProcess.success('mock_token'));

    final state = getEntity<AuthStateComponent>();
    state.update(AuthState.loggedIn);
  }
}
