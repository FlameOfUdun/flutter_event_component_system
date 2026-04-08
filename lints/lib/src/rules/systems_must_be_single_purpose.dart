import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

const _systemBaseTypes = {
  'ECSInitializeSystem',
  'ECSExecuteSystem',
  'ECSCleanupSystem',
  'ECSTeardownSystem',
  'ECSReactiveSystem',
};

/// Lint rule that ensures a system class extends only one ECS system type.
final class SystemsMustBeSinglePurpose extends DartLintRule {
  const SystemsMustBeSinglePurpose() : super(code: _code);

  static const _code = LintCode(
    name: 'systems_must_be_single_purpose',
    problemMessage: 'A system class must extend exactly one ECS system type.',
    correctionMessage:
        'Remove extra system base types. Each class should extend only one of: ECSInitializeSystem, ECSExecuteSystem, ECSCleanupSystem, ECSTeardownSystem, or ECSReactiveSystem.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((classDecl) {
      final element = classDecl.declaredFragment?.element;
      if (element == null) return;

      final matched = _matchedSystemTypes(element);
      if (matched.length > 1) {
        reporter.atToken(classDecl.name, _code);
      }
    });
  }

  Set<String> _matchedSystemTypes(ClassElement element) {
    final matched = <String>{};

    final supertype = element.supertype;
    if (supertype != null) {
      _collectMatches(supertype.element, matched);
    }

    for (final interface in element.interfaces) {
      _collectMatches(interface.element, matched);
    }

    for (final mixin in element.mixins) {
      _collectMatches(mixin.element, matched);
    }

    return matched;
  }

  void _collectMatches(Element? element, Set<String> matched) {
    if (element is! ClassElement) return;
    final name = element.name;
    if (name == null) return;
    if (_systemBaseTypes.contains(name)) {
      matched.add(name);
      return;
    }

    // Walk supertype
    final supertype = element.supertype;
    if (supertype != null) {
      _collectMatches(supertype.element, matched);
    }

    // Walk interfaces of intermediate classes too
    for (final interface in element.interfaces) {
      _collectMatches(interface.element, matched);
    }

    // Walk mixins of intermediate classes too
    for (final mixin in element.mixins) {
      _collectMatches(mixin.element, matched);
    }
  }
}
