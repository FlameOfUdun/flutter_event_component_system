import 'package:flutter_ecs_example/features/navigation_feature/navigation_feature.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'models/login_credentials.dart';
part 'models/auth_state.dart';
part 'models/login_process.dart';
part 'models/logout_process.dart';

part 'user_auth_feature.ecs.g.dart';

@Component()
var authState = AuthState.loggedOut;

@Component()
LoginProcess loginProcess = const LoginProcess.idle();

@Component()
LogoutProcess logoutProcess = const LogoutProcess.idle();

@Event()
void login(LoginCredentials credentials) {
  handleLogin(credentials);
}

@Event()
void logout() {
  handleLogout();
}

@Event()
void reloadUser() {
  handleReload();
}

@Event()
void notifyAuthStateChange() {
  handleNavigateToDashboardWhenLoggedIn();
  navigateToLoginWhenLoggedOut();
}

@ReactiveSystem(reactsIf: handleLoginIf)
void handleLogin(LoginCredentials credentials) {
  _performLogin(credentials).ignore();
}

bool handleLoginIf() {
  return loginProcess.isRunning == false;
}

Future<void> _performLogin(LoginCredentials credentials) async {
  loginProcess = const LoginProcess.running();
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('auth_state', AuthState.loggedIn.name);
  await Future.delayed(const Duration(seconds: 2));
  loginProcess = const LoginProcess.success('mock_token');
  authState = AuthState.loggedIn;
  notifyAuthStateChange();
}

@ReactiveSystem(reactsIf: handleLogoutIf)
void handleLogout() {
  _performLogout().ignore();
}

bool handleLogoutIf() {
  return logoutProcess.isRunning == false;
}

Future<void> _performLogout() async {
  logoutProcess = const LogoutProcess.running();
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('auth_state', AuthState.loggedOut.name);
  await Future.delayed(const Duration(seconds: 1));
  logoutProcess = const LogoutProcess.success();
  authState = AuthState.loggedOut;
  notifyAuthStateChange();
}

@ReactiveSystem()
void handleReload() {
  _performReload().ignore();
}

Future<void> _performReload() async {
  final preferences = await SharedPreferences.getInstance();
  final value = preferences.getString('auth_state');
  authState = value == null ? AuthState.loggedOut : AuthState.values.byName(value);
  notifyAuthStateChange();
}
