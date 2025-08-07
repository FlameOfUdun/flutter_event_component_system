part of '../navigation_feature.dart';

final class AppRouteComponent extends ECSComponent<AppRoutes> {
  AppRouteComponent([super.value = AppRoutes.home]);
}

enum AppRoutes {
  home,
  login,
  dashboard,
}

extension AppRoutesExtension on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.home:
        return '/';
      case AppRoutes.login:
        return '/login';
      case AppRoutes.dashboard:
        return '/dashboard';
    }
  }
}

