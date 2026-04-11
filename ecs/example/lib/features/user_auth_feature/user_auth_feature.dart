import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'models/auth_credentials.dart';
part 'models/auth_state.dart';
part 'models/auth_process.dart';

part 'user_auth_feature.ecs.g.dart';

final userAuthFeature = ECS.createFeature();

final authState = userAuthFeature.addComponent(AuthState.unknown);
final loginProcess = userAuthFeature.addComponent(const AuthProcess.idle());
final logoutProcess = userAuthFeature.addComponent(const AuthProcess.idle());
final reloadProcess = userAuthFeature.addComponent(const AuthProcess.idle());

final login = userAuthFeature.addDataEvent<AuthCredentials>();
final logout = userAuthFeature.addEvent();
final reloadUser = userAuthFeature.addEvent();

final loginHandler = userAuthFeature.addReactiveSystem(
  reactsTo: {login},
  reactsIf: () {
    return loginProcess.value.isRunning == false;
  },
  react: () {
    _performLogin(login.data);
  },
);

void _performLogin(AuthCredentials credentials) async {
  try {
    loginProcess.value = const AuthProcess.running();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));
    authState.value = AuthState.loggedIn;
    loginProcess.value = const AuthProcess.success('mock_token');
  } catch (e) {
    loginProcess.value = AuthProcess.failure(e.toString());
  }
}

final logoutHandler = userAuthFeature.addReactiveSystem(
  reactsTo: {logout},
  reactsIf: () {
    return logoutProcess.value.isRunning == false;
  },
  react: () {
    _performLogout();
  },
);

void _performLogout() async {
  logoutProcess.value = const AuthProcess.running();
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedOut.name);
    await Future.delayed(const Duration(seconds: 1));
    authState.value = AuthState.loggedOut;
    logoutProcess.value = const AuthProcess.success(null);
  } catch (e) {
    logoutProcess.value = AuthProcess.failure(e.toString());
  }
}

final reloadHandler = userAuthFeature.addReactiveSystem(
  reactsTo: {reloadUser},
  reactsIf: () {
    return reloadProcess.value.isRunning == false;
  },
  react: () {
    _performReload();
  },
);

void _performReload() async {
  reloadProcess.value = const AuthProcess.running();
  try {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('auth_state');
    authState.value = value == null ? AuthState.loggedOut : AuthState.values.byName(value);
    reloadProcess.value = const AuthProcess.success(null);
  } catch (e) {
    reloadProcess.value = AuthProcess.failure(e.toString());
  }
}
