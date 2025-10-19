import 'package:flutter/material.dart';
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

  @override
  Widget buildInspector(BuildContext context) {
    return _LoadUserEventInspector(
      userId: userId,
      trigger: triggerWithUserId,
    );
  }
}

class _LoadUserEventInspector extends StatefulWidget {
  final String? userId;
  final ValueChanged<String> trigger;

  const _LoadUserEventInspector({
    required this.userId,
    required this.trigger,
  });

  @override
  State<_LoadUserEventInspector> createState() => _LoadUserEventInspectorState();
}

class _LoadUserEventInspectorState extends State<_LoadUserEventInspector> {
  final controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.userId ?? '';
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _LoadUserEventInspector oldWidget) {
    if (oldWidget.userId != widget.userId) {
      controller.text = widget.userId ?? '';
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'User ID',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final userId = controller.text.trim();
            if (userId.isEmpty) return;
            widget.trigger(userId);
          },
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
