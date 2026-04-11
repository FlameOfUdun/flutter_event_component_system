part of '../user_auth_feature.dart';

final class AuthProcess<T> {
  final bool isRunning;
  final T? data;
  final Object? error;

  const AuthProcess.idle()
      : isRunning = false,
        data = null,
        error = null;

  const AuthProcess.running()
      : isRunning = true,
        data = null,
        error = null;

  const AuthProcess.success(this.data)
      : isRunning = false,
        error = null;

  const AuthProcess.failure(this.error)
      : isRunning = false,
        data = null;

  bool get isSuccessful => !isRunning && data != null;
  bool get isFailed => !isRunning && error != null;
  bool get isIdle => !isRunning && data == null && error == null;
}
