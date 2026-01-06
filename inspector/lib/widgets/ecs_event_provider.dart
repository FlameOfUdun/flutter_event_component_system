import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../models/ecs_inspector_data.dart';

final class ECSEventProvider extends InheritedWidget {
  const ECSEventProvider({super.key, required super.child});

  static ECSEventProvider of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ECSEventProvider>();
    if (widget == null) {
      throw FlutterError('ECSEventProvider not found in context');
    }
    return widget;
  }

  static ECSEventProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ECSEventProvider>();
  }

  Future<void> waitForServiceInit() async {
    await Future.doWhile(() async {
      if (serviceManager.service != null) return false;
      return Future.delayed(const Duration(seconds: 1), () => true);
    });
  }

  /// Requests the current ECS inspector data from the service extension.
  Future<ECSInspectorData> requestInspectorData() async {
    final response = await serviceManager.service!.callServiceExtension(
      'ext.ecs.requestInspectorData',
      isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
    );
    return ECSInspectorData.fromJson(response.json!);
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
