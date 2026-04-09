// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user_auth_feature.dart';

// **************************************************************************
// ComponentGenerator
// **************************************************************************

final class AuthStateComponent extends ECSComponent<AuthState> {
  AuthStateComponent([super.value = AuthState.loggedOut]);
}

final class LoginProcessComponent extends ECSComponent<LoginProcess> {
  LoginProcessComponent([super.value = const LoginProcess.idle()]);
}

final class LogoutProcessComponent extends ECSComponent<LogoutProcess> {
  LogoutProcessComponent([super.value = const LogoutProcess.idle()]);
}

// **************************************************************************
// EventGenerator
// **************************************************************************

final class LoginEvent extends ECSDataEvent<LoginCredentials> {}

final class LogoutEvent extends ECSEvent {}

final class ReloadUserEvent extends ECSEvent {}

// **************************************************************************
// ReactiveSystemGenerator
// **************************************************************************

final class HandleLoginReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {LoginEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {LoginProcessComponent, AuthStateComponent};
  }

  @override
  void react() {
    _performLogin(getEntity<LoginEvent>().data).ignore();
  }

  Future<void> _performLogin(LoginCredentials credentials) {
    getEntity<LoginProcessComponent>().value = const LoginProcess.running();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));
    getEntity<LoginProcessComponent>().value =
        const LoginProcess.success('mock_token');
    getEntity<AuthStateComponent>().value = AuthState.loggedIn;
  }
}

final class HandleLogoutReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {};
  }

  @override
  Set<Type> get interactsWith {
    return const {LogoutProcessComponent, AuthStateComponent};
  }

  @override
  void react() {
    _performLogout().ignore();
  }

  Future<void> _performLogout() {
    getEntity<LogoutProcessComponent>().value = const LogoutProcess.running();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedOut.name);
    await Future.delayed(const Duration(seconds: 1));
    getEntity<LogoutProcessComponent>().value = const LogoutProcess.success();
    getEntity<AuthStateComponent>().value = AuthState.loggedOut;
  }
}

final class HandleReloadReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {};
  }

  @override
  Set<Type> get interactsWith {
    return const {AuthStateComponent};
  }

  @override
  void react() {
    _performReload().ignore();
  }

  Future<void> _performReload() {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('auth_state');
    getEntity<AuthStateComponent>().value =
        value == null ? AuthState.loggedOut : AuthState.values.byName(value);
  }
}

// **************************************************************************
// FeatureGenerator
// **************************************************************************

final class UserAuthFeature extends ECSFeature {
  UserAuthFeature() {
    addEntity(AuthStateComponent());
    addEntity(LoginProcessComponent());
    addEntity(LogoutProcessComponent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());
    addEntity(ReloadUserEvent());
    addSystem(HandleLoginReactiveSystem());
    addSystem(HandleLogoutReactiveSystem());
    addSystem(HandleReloadReactiveSystem());
  }
}
