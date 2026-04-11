import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import '../models/manager_model.dart';

final class ModifiedEntityCollector extends RecursiveAstVisitor<void> {
  final ManagerModel manager;
  final Set<VariableElement> entities = {};

  ModifiedEntityCollector(this.manager);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final lhs = node.leftHandSide;

    VariableElement? variable;
    if (lhs is PropertyAccess && lhs.propertyName.name == 'value') {
      variable = extractVariable(lhs.target);
    } else if (lhs is PrefixedIdentifier && lhs.identifier.name == 'value') {
      variable = resolveToVariable(lhs.prefix.element);
    }

    if (variable != null && manager.getEntity(variable) != null) {
      entities.add(variable);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final method = node.methodName.name;

    if (node.target != null) {
      if (method == 'trigger' || method == 'update') {
        final variable = extractVariable(node.target);
        if (variable != null && manager.getEntity(variable) != null) {
          entities.add(variable);
        }
      }
    } else {
      final variable = resolveToVariable(node.methodName.element);
      if (variable != null && manager.getEntity(variable) != null) {
        entities.add(variable);
      }
    }

    super.visitMethodInvocation(node);
  }
}
