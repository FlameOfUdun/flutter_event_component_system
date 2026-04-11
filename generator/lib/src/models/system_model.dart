import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import 'feature_model.dart';
import 'manager_model.dart';

sealed class SystemModel {
  final String name;
  late final String ecsType;
  final List<FunctionDeclaration> helpers;

  FeatureModel? feature;

  SystemModel({
    required this.name,
    required String suffix,
    this.helpers = const [],
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith(suffix) ? capitalized : '$capitalized$suffix';
  }

  String generate();

  List<FunctionBody> get _bodiesToScan;

  void _writeInteractsWith(StringBuffer buffer, ManagerModel manager) {
    final modified = extractModifiedEntities(_bodiesToScan, manager).map((v) => manager.getEntity(v)?.ecsType).whereType<String>().toSet();

    if (modified.isEmpty) return;

    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get interactsWith {');
    buffer.writeln('    return const {${modified.join(', ')}};');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _writeGuard(StringBuffer buffer, String guardName, FunctionBody? guard, ManagerModel manager) {
    if (guard == null) return;
    buffer.writeln('  @override');
    buffer.writeln('  bool get $guardName ${rewriteFunctionBody(guard, manager)}');
  }

  void _writeHelpers(StringBuffer buffer, ManagerModel manager) {
    for (final helper in helpers) {
      buffer.writeln();
      final ret = helper.returnType?.toSource();
      final hName = helper.name.lexeme;
      final params = helper.functionExpression.parameters?.toSource() ?? '()';
      final body = rewriteFunctionBody(helper.functionExpression.body, manager);
      buffer.write('  ${ret != null ? '$ret ' : ''}$hName$params $body');
    }
  }
}

final class ReactiveSystemModel extends SystemModel {
  final Set<VariableElement> reactsTo;
  final FunctionBody? reactsIf;
  final FunctionBody react;

  ReactiveSystemModel({
    required super.name,
    required this.reactsTo,
    required this.react,
    this.reactsIf,
    super.helpers,
  }) : super(suffix: 'ReactiveSystem');

  @override
  List<FunctionBody> get _bodiesToScan {
    return [
      react,
      ...helpers.map((h) => h.functionExpression.body),
    ];
  }

  @override
  String generate() {
    final manager = feature!.manager!;

    final reactsToTokens = reactsTo.map((e) => manager.getEntity(e)?.ecsType ?? e.name!).join(', ');

    final buffer = StringBuffer('final class $ecsType extends ECSReactiveSystem {\n');
    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get reactsTo {');
    buffer.writeln('    return const {$reactsToTokens};');
    buffer.writeln('  }');
    buffer.writeln();
    _writeInteractsWith(buffer, manager);
    _writeGuard(buffer, 'reactsIf', reactsIf, manager);
    buffer.writeln('  @override');
    buffer.write('  void react() ${rewriteFunctionBody(react, manager)}');
    _writeHelpers(buffer, manager);
    buffer.write('\n}');
    return buffer.toString();
  }
}

final class ExecuteSystemModel extends SystemModel {
  final FunctionBody execute;
  final FunctionBody? executesIf;

  ExecuteSystemModel({
    required super.name,
    required this.execute,
    this.executesIf,
    super.helpers,
  }) : super(suffix: 'ExecuteSystem');

  @override
  List<FunctionBody> get _bodiesToScan => [
        execute,
        ...helpers.map((h) => h.functionExpression.body),
      ];

  @override
  String generate() {
    final manager = feature!.manager!;

    final buffer = StringBuffer('final class $ecsType extends ECSExecuteSystem {\n');
    _writeInteractsWith(buffer, manager);
    _writeGuard(buffer, 'executesIf', executesIf, manager);
    buffer.writeln('  @override');
    buffer.write('  void execute(Duration elapsed) ${rewriteFunctionBody(execute, manager)}');
    _writeHelpers(buffer, manager);
    buffer.write('\n}');
    return buffer.toString();
  }
}

final class CleanupSystemModel extends SystemModel {
  final FunctionBody cleanup;
  final FunctionBody? cleansIf;

  CleanupSystemModel({
    required super.name,
    required this.cleanup,
    this.cleansIf,
    super.helpers,
  }) : super(suffix: 'CleanupSystem');

  @override
  List<FunctionBody> get _bodiesToScan {
    return [
      cleanup,
      ...helpers.map((h) => h.functionExpression.body),
    ];
  }

  @override
  String generate() {
    final manager = feature!.manager!;

    final buffer = StringBuffer('final class $ecsType extends ECSCleanupSystem {\n');
    _writeInteractsWith(buffer, manager);
    _writeGuard(buffer, 'cleansIf', cleansIf, manager);
    buffer.writeln('  @override');
    buffer.write('  void cleanup() ${rewriteFunctionBody(cleanup, manager)}');
    _writeHelpers(buffer, manager);
    buffer.write('\n}');
    return buffer.toString();
  }
}

final class TeardownSystemModel extends SystemModel {
  final FunctionBody teardown;

  TeardownSystemModel({
    required super.name,
    required this.teardown,
    super.helpers,
  }) : super(suffix: 'TeardownSystem');

  @override
  List<FunctionBody> get _bodiesToScan {
    return [
      teardown,
      ...helpers.map((h) => h.functionExpression.body),
    ];
  }

  @override
  String generate() {
    final manager = feature!.manager!;

    final buffer = StringBuffer('final class $ecsType extends ECSTeardownSystem {\n');
    _writeInteractsWith(buffer, manager);
    buffer.writeln('  @override');
    buffer.write('  void teardown() ${rewriteFunctionBody(teardown, manager)}');
    _writeHelpers(buffer, manager);
    buffer.write('\n}');
    return buffer.toString();
  }
}

final class InitializeSystemModel extends SystemModel {
  final FunctionBody initialize;

  InitializeSystemModel({
    required super.name,
    required this.initialize,
    super.helpers,
  }) : super(suffix: 'InitializeSystem');

  @override
  List<FunctionBody> get _bodiesToScan {
    return [
      initialize,
      ...helpers.map((h) => h.functionExpression.body),
    ];
  }

  @override
  String generate() {
    final manager = feature!.manager!;

    final buffer = StringBuffer('final class $ecsType extends ECSInitializeSystem {\n');
    _writeInteractsWith(buffer, manager);
    buffer.writeln('  @override');
    buffer.write('  void initialize() ${rewriteFunctionBody(initialize, manager)}');
    _writeHelpers(buffer, manager);
    buffer.write('\n}');
    return buffer.toString();
  }
}
