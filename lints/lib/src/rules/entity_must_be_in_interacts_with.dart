import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule that enforces entities updated anywhere in an ECSSystem
/// must be declared in the `interactsWith` getter.
///
/// Update actions detected:
/// - ECSDataEvent/ECSEvent → trigger()
/// - ECSComponent → update() or .value setter
final class EntityMustBeInInteractsWith extends DartLintRule {
  const EntityMustBeInInteractsWith() : super(code: _code);

  static const _code = LintCode(
    name: 'entity_must_be_in_interacts_with',
    problemMessage: 'Entity updated in ECSSystem must be declared in interactsWith.',
    correctionMessage: 'Add this entity type to the interactsWith getter.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((classDecl) {
      // Check if class extends ECSSystem
      if (!_extendsECSSystem(classDecl)) return;

      // Get declared interactsWith types
      final interactsWithTypes = _getInteractsWithTypes(classDecl);

      // Check ALL methods in the class for entity updates
      for (final member in classDecl.members) {
        if (member is MethodDeclaration) {
          member.body.accept(_EntityUpdateVisitor(
            interactsWithTypes: interactsWithTypes,
            reporter: reporter,
            code: _code,
          ));
        }
      }
    });
  }

  bool _extendsECSSystem(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superType = extendsClause.superclass.type;
    if (superType is! InterfaceType) return false;

    final superElement = superType.element;
    if (superElement is! ClassElement) return false;

    return _elementExtendsECSSystem(superElement);
  }

  bool _elementExtendsECSSystem(ClassElement element) {
    if (element.name == 'ECSSystem') return true;

    final supertype = element.supertype;
    if (supertype == null) return false;

    final superElement = supertype.element;
    if (superElement is! ClassElement) return false;

    return _elementExtendsECSSystem(superElement);
  }

  Set<String> _getInteractsWithTypes(ClassDeclaration classDecl) {
    final types = <String>{};

    for (final member in classDecl.members) {
      if (member is MethodDeclaration &&
          member.name.lexeme == 'interactsWith' &&
          member.isGetter) {
        member.body.accept(_InteractsWithVisitor(types));
      }
    }

    return types;
  }
}

/// Visitor to extract types from interactsWith getter
class _InteractsWithVisitor extends GeneralizingAstVisitor<void> {
  _InteractsWithVisitor(this.types);

  final Set<String> types;

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isSet) {
      for (final element in node.elements) {
        if (element is SimpleIdentifier) {
          types.add(element.name);
        }
      }
    }
    super.visitSetOrMapLiteral(node);
  }
}

/// Visitor to find entity updates in any method
class _EntityUpdateVisitor extends GeneralizingAstVisitor<void> {
  _EntityUpdateVisitor({
    required this.interactsWithTypes,
    required this.reporter,
    required this.code,
  });

  final Set<String> interactsWithTypes;
  final DiagnosticReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Check for trigger() or update() calls
    if (methodName == 'trigger' || methodName == 'update') {
      final target = node.target;

      // Pattern: getEntity<T>().trigger() or getEntity<T>().update()
      if (target is MethodInvocation && target.methodName.name == 'getEntity') {
        final typeArg = _getTypeArgument(target);
        if (typeArg != null && !interactsWithTypes.contains(typeArg)) {
          reporter.atNode(node, code);
        }
      }
      // Pattern: variable.trigger() or variable.update()
      else if (target != null) {
        _checkTargetType(node, target);
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;

    // Pattern: entity.value = x or getEntity<T>().value = x
    if (left is PropertyAccess && left.propertyName.name == 'value') {
      final target = left.target;

      if (target is MethodInvocation && target.methodName.name == 'getEntity') {
        final typeArg = _getTypeArgument(target);
        if (typeArg != null && !interactsWithTypes.contains(typeArg)) {
          reporter.atNode(node, code);
        }
      } else if (target != null) {
        _checkTargetType(node, target);
      }
    }

    // Pattern: variable.value = x (PrefixedIdentifier form)
    if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      _checkPrefixType(node, left.prefix);
    }

    super.visitAssignmentExpression(node);
  }

  void _checkTargetType(AstNode reportNode, Expression target) {
    final targetType = target.staticType;
    if (targetType is InterfaceType) {
      final typeName = targetType.element.name;
      if (!interactsWithTypes.contains(typeName) && _isECSEntity(targetType)) {
        reporter.atNode(reportNode, code);
      }
    }
  }

  void _checkPrefixType(AstNode reportNode, SimpleIdentifier prefix) {
    final targetType = prefix.staticType;
    if (targetType is InterfaceType) {
      final typeName = targetType.element.name;
      if (!interactsWithTypes.contains(typeName) && _isECSComponent(targetType)) {
        reporter.atNode(reportNode, code);
      }
    }
  }

  String? _getTypeArgument(MethodInvocation getEntityCall) {
    final typeArgs = getEntityCall.typeArguments;
    if (typeArgs == null || typeArgs.arguments.isEmpty) return null;
    return typeArgs.arguments.first.toSource();
  }

  bool _isECSEntity(InterfaceType type) {
    final element = type.element;
    if (element is! ClassElement) return false;
    return _elementExtendsAny(element, ['ECSEntity', 'ECSEvent', 'ECSDataEvent', 'ECSComponent']);
  }

  bool _isECSComponent(InterfaceType type) {
    final element = type.element;
    if (element is! ClassElement) return false;
    return _elementExtendsAny(element, ['ECSComponent']);
  }

  bool _elementExtendsAny(ClassElement element, List<String> classNames) {
    if (classNames.contains(element.name)) return true;

    final supertype = element.supertype;
    if (supertype == null) return false;

    final superElement = supertype.element;
    if (superElement is! ClassElement) return false;

    return _elementExtendsAny(superElement, classNames);
  }
}
