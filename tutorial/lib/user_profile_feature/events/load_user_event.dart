import 'package:flutter_event_component_system/flutter_event_component_system.dart';

class LoadUserEvent extends ECSEvent {
  String? userId;

  void triggerWithUserId(String id) {
    userId = id;
    trigger();
  }

  void clearData() {
    userId = null;
  }
}
