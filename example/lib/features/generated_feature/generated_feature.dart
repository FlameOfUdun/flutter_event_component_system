import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

part 'generated_feature.ecs.g.dart';

@Component() int health = 0;

@Event(description: 'Resets health to 0 for testing purposes.')
void resetHealth() { applyResetHealth(); }

@Event() void addHealth(int amount) { applyAddHealth(amount); }

@ReactiveSystem()
void applyAddHealth(int amount) {
  health += amount;
}

@ReactiveSystem()
void applyResetHealth() {
  health = 0;
}
