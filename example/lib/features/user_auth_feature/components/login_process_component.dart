part of '../user_auth_feature.dart';

final class LoginProcessComponent extends ECSComponent<LoginProcess> {
  LoginProcessComponent([super.value = const LoginProcess.idle()]);
}

final class LoginProcess {
  final bool isRunning;
  final String? token;
  final Object? error;

  const LoginProcess.idle()
      : isRunning = false,
        token = null,
        error = null;

  const LoginProcess.running()
      : isRunning = true,
        token = null,
        error = null;

  const LoginProcess.success(this.token)
      : isRunning = false,
        error = null;

  const LoginProcess.failure(this.error)
      : isRunning = false,
        token = null;

  bool get isSuccessful => !isRunning && token != null;
  bool get isFailed => !isRunning && error != null;
  bool get isIdle => !isRunning && token == null && error == null;

  @override
  String toString() {
    return 'LoginProcess(isRunning: $isRunning, token: $token, error: $error)';
  }
}
