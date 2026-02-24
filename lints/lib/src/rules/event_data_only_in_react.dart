import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule that ensures `ECSDataEvent.data` is only accessed inside
/// the `react()` method of a `ReactiveSystem`.
///
/// The data property is only valid during the synchronous execution of
/// `react()` and gets nullified immediately after notifying listeners.
final class EventDataOnlyInReact extends DartLintRule {
  const EventDataOnlyInReact() : super(code: _code);

  static const _code = LintCode(
    name: 'event_data_only_in_react',
    problemMessage: 'ECSDataEvent.data should only be accessed inside react().',
    correctionMessage:
        'Move the data access to react() and pass the data as a parameter.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Handle PropertyAccess: event.data
    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name != 'data') return;
      if (!_isOnECSDataEvent(node.target?.staticType)) return;
      if (_isInsideReactMethod(node)) return;

      reporter.atNode(node, _code);
    });

    // Handle PrefixedIdentifier: event.data
    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name != 'data') return;
      if (!_isOnECSDataEvent(node.prefix.staticType)) return;
      if (_isInsideReactMethod(node)) return;

      reporter.atNode(node, _code);
    });
  }

  bool _isOnECSDataEvent(DartType? type) {
    if (type == null || type is! InterfaceType) return false;

    final element = type.element;
    if (element is! ClassElement) return false;

    return _classExtendsECSDataEvent(element);
  }

  bool _classExtendsECSDataEvent(ClassElement element) {
    if (element.name == 'ECSDataEvent') return true;

    final supertype = element.supertype;
    if (supertype == null) return false;

    final superElement = supertype.element;
    if (superElement is! ClassElement) return false;

    return _classExtendsECSDataEvent(superElement);
  }

  bool _isInsideReactMethod(AstNode node) {
    // Walk up to find the enclosing method
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method == null) return false;

    // Check if method is named 'react'
    if (method.name.lexeme != 'react') return false;

    // Check if the class extends ReactiveSystem
    final classDecl = method.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return false;

    return _classExtendsReactiveSystem(classDecl);
  }

  bool _classExtendsReactiveSystem(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superType = extendsClause.superclass.type;
    if (superType is! InterfaceType) return false;

    final superElement = superType.element;
    if (superElement is! ClassElement) return false;

    return _elementExtendsReactiveSystem(superElement);
  }

  bool _elementExtendsReactiveSystem(ClassElement element) {
    if (element.name == 'ReactiveSystem') return true;

    final supertype = element.supertype;
    if (supertype == null) return false;

    final superElement = supertype.element;
    if (superElement is! ClassElement) return false;

    return _elementExtendsReactiveSystem(superElement);
  }
}
