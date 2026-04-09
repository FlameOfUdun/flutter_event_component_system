// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user_auth_feature.dart';

// **************************************************************************
// ComponentGenerator
// **************************************************************************

final class AuthStateComponent extends ECSComponent<AuthState> {
  AuthStateComponent() : super(AuthState.unknown);
}

final class LoginProcessComponent extends ECSComponent<AuthProcess<String>> {
  LoginProcessComponent() : super(const AuthProcess.idle());
}

final class LogoutProcessComponent extends ECSComponent<AuthProcess<void>> {
  LogoutProcessComponent() : super(const AuthProcess.idle());
}

final class ReloadProcessComponent extends ECSComponent<AuthProcess<void>> {
  ReloadProcessComponent() : super(const AuthProcess.idle());
}

// **************************************************************************
// EventGenerator
// **************************************************************************

final class LoginEvent extends ECSDataEvent<AuthCredentials> {}

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
  bool get reactsIf {
    return getEntity<LoginProcessComponent>().value.isRunning == false;
  }

  @override
  void react() {
    _performLogin(getEntity<LoginEvent>().data);
  }

  void _performLogin(AuthCredentials credentials) async {
    try {
      getEntity<LoginProcessComponent>().value = const AuthProcess.running();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_state', AuthState.loggedIn.name);
      await Future.delayed(const Duration(seconds: 2));
      getEntity<AuthStateComponent>().value = AuthState.loggedIn;
      getEntity<LoginProcessComponent>().value =
          const AuthProcess.success('mock_token');
    } catch (e) {
      getEntity<LoginProcessComponent>().value =
          AuthProcess.failure(e.toString());
    }
  }
}

final class HandleLogoutReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {LogoutEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {LogoutProcessComponent, AuthStateComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<LogoutProcessComponent>().value.isRunning == false;
  }

  @override
  void react() {
    _performLogout();
  }

  void _performLogout() async {
    getEntity<LogoutProcessComponent>().value = const AuthProcess.running();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_state', AuthState.loggedOut.name);
      await Future.delayed(const Duration(seconds: 1));
      getEntity<AuthStateComponent>().value = AuthState.loggedOut;
      getEntity<LogoutProcessComponent>().value =
          const AuthProcess.success(null);
    } catch (e) {
      getEntity<LogoutProcessComponent>().value =
          AuthProcess.failure(e.toString());
    }
  }
}

final class HandleReloadReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {ReloadUserEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {ReloadProcessComponent, AuthStateComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<ReloadProcessComponent>().value.isRunning == false;
  }

  @override
  void react() {
    _performReload();
  }

  void _performReload() async {
    getEntity<ReloadProcessComponent>().value = const AuthProcess.running();
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString('auth_state');
      getEntity<AuthStateComponent>().value =
          value == null ? AuthState.loggedOut : AuthState.values.byName(value);
      getEntity<ReloadProcessComponent>().value =
          const AuthProcess.success(null);
    } catch (e) {
      getEntity<ReloadProcessComponent>().value =
          AuthProcess.failure(e.toString());
    }
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
    addEntity(ReloadProcessComponent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());
    addEntity(ReloadUserEvent());
    addSystem(HandleLoginReactiveSystem());
    addSystem(HandleLogoutReactiveSystem());
    addSystem(HandleReloadReactiveSystem());
  }
}
