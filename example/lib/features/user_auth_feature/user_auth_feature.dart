import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'models/auth_credentials.dart';
part 'models/auth_state.dart';
part 'models/auth_process.dart';

part 'user_auth_feature.ecs.g.dart';

@Component()
var authState = AuthState.unknown;

@Component()
AuthProcess<String> loginProcess = const AuthProcess.idle();

@Component()
AuthProcess<void> logoutProcess = const AuthProcess.idle();

@Component()
AuthProcess<void> reloadProcess = const AuthProcess.idle();

@Event()
void login(AuthCredentials credentials) {}

@Event()
void logout() {}

@Event()
void reloadUser() {}

@ReactiveSystem()
class HandleLogin {
  List get reactsTo {
    return [login];
  }

  bool get reactsIf {
    return loginProcess.isRunning == false;
  }

  void react(AuthCredentials credentials) {
    _performLogin(credentials);
  }
}

void _performLogin(AuthCredentials credentials) async {
  try {
    loginProcess = const AuthProcess.running();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));
    authState = AuthState.loggedIn;
    loginProcess = const AuthProcess.success('mock_token');
  } catch (e) {
    loginProcess = AuthProcess.failure(e.toString());
  }
}

@ReactiveSystem()
class HandleLogout {
  List get reactsTo {
    return [logout];
  }

  bool get reactsIf {
    return logoutProcess.isRunning == false;
  }

  void react() {
    _performLogout();
  }
}

void _performLogout() async {
  logoutProcess = const AuthProcess.running();
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedOut.name);
    await Future.delayed(const Duration(seconds: 1));
    authState = AuthState.loggedOut;
    logoutProcess = const AuthProcess.success(null);
  } catch (e) {
    logoutProcess = AuthProcess.failure(e.toString());
  }
}

@ReactiveSystem()
class HandleReload {
  List get reactsTo {
    return [reloadUser];
  }

  bool get reactsIf {
    return reloadProcess.isRunning == false;
  }

  void react() {
    _performReload();
  }
}

void _performReload() async {
  reloadProcess = const AuthProcess.running();
  try {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('auth_state');
    authState = value == null ? AuthState.loggedOut : AuthState.values.byName(value);
    reloadProcess = const AuthProcess.success(null);
  } catch (e) {
    reloadProcess = AuthProcess.failure(e.toString());
  }
}
