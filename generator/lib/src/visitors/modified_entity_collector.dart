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
    _checkValueAccess(node.leftHandSide);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final op = node.operator.lexeme;
    if (op == '++' || op == '--') _checkValueAccess(node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final op = node.operator.lexeme;
    if (op == '++' || op == '--') _checkValueAccess(node.operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final method = node.methodName.name;
    if (node.target != null) {
      if (method == 'trigger' || method == 'update') {
        _addIfEntity(extractVariable(node.target));
      }
    } else {
      _addIfEntity(resolveToVariable(node.methodName.element));
    }
    super.visitMethodInvocation(node);
  }

  void _checkValueAccess(Expression operand) {
    VariableElement? variable;
    if (operand is PropertyAccess && operand.propertyName.name == 'value') {
      variable = extractVariable(operand.target);
    } else if (operand is PrefixedIdentifier && operand.identifier.name == 'value') {
      variable = resolveToVariable(operand.prefix.element);
    }
    _addIfEntity(variable);
  }

  void _addIfEntity(VariableElement? variable) {
    if (variable != null && manager.getEntity(variable) != null) {
      entities.add(variable);
    }
  }
}
