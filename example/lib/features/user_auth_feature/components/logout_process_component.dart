part of '../user_auth_feature.dart';

final class LogoutProcessComponent extends ECSComponent<LogoutProcess> {
  LogoutProcessComponent([super.value = const LogoutProcess.idle()]);
}

final class LogoutProcess {
  final bool isRunning;
  final bool isSuccessful;
  final Object? error;

  const LogoutProcess.idle()
      : isRunning = false,
        isSuccessful = false,
        error = null;

  const LogoutProcess.running()
      : isRunning = true,
        isSuccessful = false,
        error = null;

  const LogoutProcess.success()
      : isRunning = false,
        isSuccessful = true,
        error = null;

  bool get isFailed => !isRunning && error != null;
  bool get isIdle => !isRunning && isSuccessful == false && error == null;

  @override
  String toString() {
    return 'LogoutProcess(isRunning: $isRunning, isSuccessful: $isSuccessful, error: $error)';
  }
}
