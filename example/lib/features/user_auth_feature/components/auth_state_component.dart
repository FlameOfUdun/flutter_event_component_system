part of '../user_auth_feature.dart';

final class AuthStateComponent extends ECSComponent<AuthState> {
  AuthStateComponent([super.value = AuthState.unknown]);
}

enum AuthState {
  unknown,
  loggedIn,
  loggedOut,
  mfaRequired,
}
