import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import 'models/manager_model.dart';
import 'visitors/modified_entity_collector.dart';

Set<VariableElement> extractModifiedEntities(
  List<FunctionBody> bodies,
  ManagerModel manager,
) {
  final collector = ModifiedEntityCollector(manager);
  for (final body in bodies) {
    body.accept(collector);
  }
  return collector.entities;
}

VariableElement? resolveToVariable(Element? element) {
  if (element is VariableElement) return element;
  if (element is PropertyAccessorElement) return element.variable as VariableElement?;
  return null;
}

VariableElement? extractVariable(Expression? expr) {
  return switch (expr) {
    SimpleIdentifier() => resolveToVariable(expr.element),
    PrefixedIdentifier() => resolveToVariable(expr.identifier.element),
    PropertyAccess() => extractVariable(expr.target),
    _ => null,
  };
}

ClassElement? extractClass(Expression? expr) {
  if (expr is SimpleIdentifier) {
    final element = expr.element;
    if (element is ClassElement) {
      return element;
    }
  }

  if (expr is PrefixedIdentifier) {
    final element = expr.identifier.element;
    if (element is ClassElement) {
      return element;
    }
  }

  if (expr is PropertyAccess) {
    final target = expr.target;
    return extractClass(target);
  }

  return null;
}

String capitalize(String input) {
  return input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
}

String rewriteExpression(Expression expr, ManagerModel manager) {
  if (expr is NamedExpression) {
    return '${expr.name.label.name}: ${rewriteExpression(expr.expression, manager)}';
  }

  if (expr is ThrowExpression) {
    return 'throw ${rewriteExpression(expr.expression, manager)}';
  }

  if (expr is IsExpression) {
    final target = rewriteExpression(expr.expression, manager);
    final bang = expr.notOperator != null ? '!' : '';
    return '$target is$bang ${expr.type.toSource()}';
  }

  if (expr is AsExpression) {
    return '${rewriteExpression(expr.expression, manager)} as ${expr.type.toSource()}';
  }

  if (expr is IndexExpression) {
    final target = rewriteExpression(expr.target!, manager);
    final index = rewriteExpression(expr.index, manager);
    return '$target[$index]';
  }

  if (expr is AssignmentExpression) {
    final lhs = rewriteExpression(expr.leftHandSide, manager);
    final rhs = rewriteExpression(expr.rightHandSide, manager);
    return '$lhs ${expr.operator.lexeme} $rhs';
  }

  if (expr is SimpleIdentifier) {
    final variable = resolveToVariable(expr.element);
    if (variable != null) {
      final entity = manager.getEntity(variable);
      if (entity != null) {
        return 'getEntity<${entity.ecsType}>()';
      }
    }
    return expr.name;
  }

  if (expr is PropertyAccess) {
    final target = rewriteExpression(expr.target!, manager);
    final op = expr.operator.lexeme; // ← '?.' or '.' or '?'
    final property = expr.propertyName.name;
    return '$target$op$property';
  }

  if (expr is PrefixedIdentifier) {
    final target = rewriteExpression(expr.prefix, manager);
    final property = expr.identifier.name;
    return '$target.$property';
  }

  if (expr is PrefixExpression) {
    final operand = rewriteExpression(expr.operand, manager);
    return '${expr.operator.lexeme}$operand';
  }

  if (expr is PostfixExpression) {
    final operand = rewriteExpression(expr.operand, manager);
    return '$operand${expr.operator.lexeme}';
  }

  if (expr is AwaitExpression) {
    return 'await ${rewriteExpression(expr.expression, manager)}';
  }

  if (expr is BinaryExpression) {
    final left = rewriteExpression(expr.leftOperand, manager);
    final right = rewriteExpression(expr.rightOperand, manager);

    return '$left ${expr.operator.lexeme} $right';
  }

  if (expr is MethodInvocation) {
    final typeArgs = expr.typeArguments?.toSource() ?? '';
    final args = expr.argumentList.arguments.map((a) => rewriteExpression(a, manager)).join(', ');

    if (expr.target != null) {
      final target = rewriteExpression(expr.target as Expression, manager);
      final op = expr.operator?.lexeme ?? '.'; // ← '?.' or '.'
      return '$target$op${expr.methodName.name}$typeArgs($args)';
    }

    return '${expr.methodName.name}$typeArgs($args)';
  }

  if (expr is ConditionalExpression) {
    final cond = rewriteExpression(expr.condition, manager);
    final then = rewriteExpression(expr.thenExpression, manager);
    final other = rewriteExpression(expr.elseExpression, manager);
    return '$cond ? $then : $other';
  }

  if (expr is InstanceCreationExpression) {
    final kw = expr.keyword?.lexeme;
    final name = expr.constructorName.toSource();
    final args = expr.argumentList.arguments.map((a) => rewriteExpression(a, manager)).join(', ');
    return kw != null ? '$kw $name($args)' : '$name($args)';
  }

  if (expr is FunctionExpressionInvocation) {
    final fn = rewriteExpression(expr.function, manager);
    final args = expr.argumentList.arguments.map((a) => rewriteExpression(a, manager)).join(', ');
    return '$fn($args)';
  }

  if (expr is ParenthesizedExpression) {
    return '(${rewriteExpression(expr.expression, manager)})';
  }

  if (expr is FunctionExpression) {
    final params = expr.parameters?.toSource() ?? '()';
    final body = rewriteFunctionBody(expr.body, manager, asClosure: true);
    return '$params $body';
  }

  return expr.toSource();
}

String rewriteFunctionBody(
  FunctionBody body,
  ManagerModel manager, {
  bool asClosure = false,
}) {
  final keyword = body.keyword?.lexeme;
  final star = body.star?.lexeme ?? '';
  final prefix = keyword == null ? '' : '$keyword$star ';

  if (body is ExpressionFunctionBody) {
    final expr = rewriteExpression(body.expression, manager);
    return '$prefix=> $expr${asClosure ? '' : ';'}';
  }

  if (body is BlockFunctionBody) {
    return '$prefix${rewriteBlock(body.block, manager)}';
  }

  return body.toSource();
}

String rewriteStatement(Statement stmt, ManagerModel manager) {
  if (stmt is ExpressionStatement) {
    final expr = stmt.expression;

    if (expr is AssignmentExpression) {
      final lhs = expr.leftHandSide;
      String lhsRepl;
      if (lhs is SimpleIdentifier) {
        final variable = resolveToVariable(lhs.element);
        if (variable != null) {
          final ent = manager.getEntity(variable);
          if (ent != null) {
            lhsRepl = 'getEntity<${ent.ecsType}>().value';
          } else {
            lhsRepl = rewriteExpression(lhs, manager);
          }
        } else {
          lhsRepl = rewriteExpression(lhs, manager);
        }
      } else {
        lhsRepl = rewriteExpression(lhs, manager);
      }

      final rhs = rewriteExpression(expr.rightHandSide, manager);
      final op = expr.operator.lexeme;
      return '$lhsRepl $op $rhs;';
    }

    if (expr is MethodInvocation && expr.target == null) {
      final variable = resolveToVariable(expr.methodName.element);
      if (variable != null) {
        final entity = manager.getEntity(variable);
        if (entity != null) {
          final args = expr.argumentList.arguments;
          if (args.isEmpty) {
            return 'getEntity<${entity.ecsType}>().trigger();';
          } else {
            final transformedArgs = args.map((a) => rewriteExpression(a, manager)).join(', ');
            return 'getEntity<${entity.ecsType}>().trigger($transformedArgs);';
          }
        }
      }
    }

    return '${rewriteExpression(expr, manager)};';
  }

  if (stmt is SwitchStatement) {
    final expr = rewriteExpression(stmt.expression, manager);
    final buffer = StringBuffer('switch ($expr) {\n');

    for (final member in stmt.members) {
      if (member is SwitchCase) {
        buffer.writeln('  case ${rewriteExpression(member.expression, manager)}:');
      } else if (member is SwitchDefault) {
        buffer.writeln('  default:');
      }
      for (final s in member.statements) {
        buffer.writeln('    ${rewriteStatement(s, manager)}');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  if (stmt is LabeledStatement) {
    final labels = stmt.labels.map((l) => '${l.label.name}:').join(' ');
    return '$labels ${rewriteStatement(stmt.statement, manager)}';
  }

  if (stmt is ReturnStatement) {
    if (stmt.expression == null) return 'return;';
    return 'return ${rewriteExpression(stmt.expression!, manager)};';
  }

  if (stmt is VariableDeclarationStatement) {
    final declList = stmt.variables;
    final kw = declList.keyword?.lexeme;
    final typeSrc = declList.type?.toSource();
    final header = kw ?? typeSrc ?? 'var';

    final parts = <String>[];
    for (final decl in declList.variables) {
      final name = decl.name.lexeme;
      final init = decl.initializer;
      if (init != null) {
        parts.add('$name = ${rewriteExpression(init, manager)}');
      } else {
        parts.add(name);
      }
    }

    return '$header ${parts.join(', ')};';
  }

  if (stmt is TryStatement) {
    final buffer = StringBuffer('try ');
    buffer.write(rewriteBlock(stmt.body, manager));

    for (final clause in stmt.catchClauses) {
      if (clause.exceptionType != null) {
        buffer.write(' on ${clause.exceptionType!.toSource()}');
      }
      if (clause.catchKeyword != null) {
        final ex = clause.exceptionParameter?.name.lexeme ?? '_';
        final st = clause.stackTraceParameter;
        buffer.write(st != null ? ' catch ($ex, ${st.name.lexeme})' : ' catch ($ex)');
      }
      buffer.write(' ');
      buffer.write(rewriteBlock(clause.body, manager));
    }

    if (stmt.finallyBlock != null) {
      buffer.write(' finally ');
      buffer.write(rewriteBlock(stmt.finallyBlock!, manager));
    }
    return buffer.toString();
  }

  if (stmt is IfStatement) {
    final cond = rewriteExpression(stmt.expression, manager);
    final then = rewriteStatement(stmt.thenStatement, manager);
    final buffer = StringBuffer('if ($cond) $then');
    if (stmt.elseStatement != null) {
      buffer.write(' else ${rewriteStatement(stmt.elseStatement!, manager)}');
    }
    return buffer.toString();
  }

  if (stmt is Block) {
    return rewriteBlock(stmt, manager);
  }

  if (stmt is WhileStatement) {
    return 'while (${rewriteExpression(stmt.condition, manager)}) '
        '${rewriteStatement(stmt.body, manager)}';
  }

  if (stmt is DoStatement) {
    return 'do ${rewriteStatement(stmt.body, manager)} '
        'while (${rewriteExpression(stmt.condition, manager)});';
  }

  if (stmt is ForStatement) {
    final body = rewriteStatement(stmt.body, manager);
    final parts = stmt.forLoopParts;
    if (parts is ForEachPartsWithDeclaration) {
      return 'for (${parts.loopVariable.toSource()} in '
          '${rewriteExpression(parts.iterable, manager)}) $body';
    }
    if (parts is ForEachPartsWithIdentifier) {
      return 'for (${parts.identifier.toSource()} in '
          '${rewriteExpression(parts.iterable, manager)}) $body';
    }
    return 'for (${parts.toSource()}) $body';
  }

  return stmt.toSource();
}

String rewriteBlock(Block block, ManagerModel manager) {
  final buffer = StringBuffer('{\n');
  for (final stmt in block.statements) {
    buffer.writeln('  ${rewriteStatement(stmt, manager)}');
  }
  buffer.write('}');
  return buffer.toString();
}
