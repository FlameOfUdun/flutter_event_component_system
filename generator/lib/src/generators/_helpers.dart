import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Converts a snake_case or camelCase filename stem to PascalCase.
/// e.g. "timer_feature" → "TimerFeature"
String toPascalCase(String stem) {
  if (stem.contains('_')) {
    return stem.split('_').map(capitalize).join();
  }
  return capitalize(stem);
}

/// Holds entity maps for DSL rewriting within a single source file.
class DslContext {
  /// varName → component class name, e.g. "health" → "HealthComponent"
  final Map<String, String> components;
  /// funcName → event class name, e.g. "logout" → "LogoutEvent"
  final Map<String, String> events;
  /// varName → dependency class name, e.g. "authRepo" → "AuthRepoDependency"
  final Map<String, String> dependencies;
  /// paramName → replacement expression, e.g. "amount" → "getEntity<AddHealthEvent>().data"
  final Map<String, String> paramReplacements;

  const DslContext({
    this.components = const {},
    this.events = const {},
    this.dependencies = const {},
    this.paramReplacements = const {},
  });

  DslContext withParamReplacements(Map<String, String> replacements) {
    return DslContext(
      components: components,
      events: events,
      dependencies: dependencies,
      paramReplacements: {...paramReplacements, ...replacements},
    );
  }
}

/// Transforms a single expression [expr] with [ctx], returning rewritten source.
/// Used for transforming individual arguments in event trigger calls.
String _transformExpr(Expression expr, DslContext ctx) {
  final source = expr.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    if (node is SimpleIdentifier) {
      final name = node.name;
      // Skip if this is a method name.
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) return;
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        replacements.add(
            (node.offset - expr.offset, node.end - expr.offset, paramReplacement));
        return;
      }
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        replacements.add((node.offset - expr.offset, node.end - expr.offset,
            'getEntity<$className>().value'));
        return;
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(expr);
  if (replacements.isEmpty) return source;
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a single statement using offset-based replacement.
/// Handles:
///   - LHS of assignments: `health = x` → `getEntity<HealthComponent>().value = x`
///   - Compound assignments: `health += x` → `getEntity<HealthComponent>().value += x`
///   - No-data event calls: `logout()` → `getEntity<LogoutEvent>().trigger()`
///   - Data event calls: `login(creds)` → `getEntity<LoginEvent>().trigger(creds)`
///   - Param replacements: `amount` → `getEntity<AddHealthEvent>().data`
///   - Component/dependency reads: `health` → `getEntity<HealthComponent>().value`
String transformDslStatement(Statement stmt, DslContext ctx) {
  final source = stmt.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    // Assignment expression: rewrite lhs only, let rhs be visited normally.
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        final name = lhs.name;
        final className = ctx.components[name] ?? ctx.dependencies[name];
        if (className != null) {
          replacements.add((
            lhs.offset - stmt.offset,
            lhs.end - stmt.offset,
            'getEntity<$className>().value',
          ));
        }
      }
      // Visit rhs only.
      visit(node.rightHandSide);
      return;
    }

    // Method invocation with no target = potential event call.
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      final className = ctx.events[name];
      if (className != null) {
        final args = node.argumentList.arguments;
        final relStart = node.offset - stmt.offset;
        final relEnd = node.end - stmt.offset;
        if (args.isEmpty) {
          replacements.add((relStart, relEnd, 'getEntity<$className>().trigger()'));
        } else {
          final transformedArgs =
              args.map((a) => _transformExpr(a, ctx)).join(', ');
          replacements
              .add((relStart, relEnd, 'getEntity<$className>().trigger($transformedArgs)'));
        }
        return;
      }
    }

    // Simple identifier: param replacement or component/dependency read.
    if (node is SimpleIdentifier) {
      final name = node.name;
      // Skip if this is a method name in an invocation.
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) {
        for (final child in node.childEntities) {
          if (child is AstNode) visit(child);
        }
        return;
      }
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        replacements.add((
          node.offset - stmt.offset,
          node.end - stmt.offset,
          paramReplacement,
        ));
        return;
      }
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        replacements.add((
          node.offset - stmt.offset,
          node.end - stmt.offset,
          'getEntity<$className>().value',
        ));
        return;
      }
    }

    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(stmt);

  if (replacements.isEmpty) return source;
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a list of statements, indenting each by 4 spaces.
String transformDslStatements(NodeList<Statement> stmts, DslContext ctx) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformDslStatement(stmt, ctx)}');
  }
  return buffer.toString();
}

/// Extracts the initializer source string from a variable declaration AST node.
/// Throws [InvalidGenerationSourceError] if no initializer is present.
String extractInitializerSource(VariableDeclaration varDecl, Element element) {
  final initializer = varDecl.initializer;
  if (initializer == null) {
    throw InvalidGenerationSourceError(
      '@Component / @Dependency variable must have an initializer to infer a default value.',
      element: element,
    );
  }
  return initializer.toSource();
}

/// Collects all private helper function names (underscore-prefixed) that are
/// transitively called from [stmts] and defined in [unit].
Set<String> collectPrivateHelpers(
  NodeList<Statement> stmts,
  CompilationUnit unit, {
  Set<String>? visited,
}) {
  final result = <String>{};
  final seen = visited ?? <String>{};

  void collect(AstNode node) {
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      if (name.startsWith('_') && !seen.contains(name)) {
        for (final decl in unit.declarations) {
          if (decl is FunctionDeclaration && decl.name.lexeme == name) {
            result.add(name);
            seen.add(name);
            final body = decl.functionExpression.body;
            if (body is BlockFunctionBody) {
              final nested = collectPrivateHelpers(
                body.block.statements,
                unit,
                visited: seen,
              );
              result.addAll(nested);
            }
            break;
          }
        }
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) collect(child);
    }
  }

  for (final stmt in stmts) {
    collect(stmt);
  }
  return result;
}

/// Detects writes (and event triggers) in [stmts] and private helpers.
/// Returns the set of component/dependency/event class names written to.
/// Reads are NOT included.
Set<String> detectInteractsWith(
  NodeList<Statement> stmts,
  CompilationUnit unit,
  DslContext ctx,
) {
  final result = <String>{};

  void collectWrites(AstNode node) {
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        final className = ctx.components[lhs.name] ?? ctx.dependencies[lhs.name];
        if (className != null) result.add(className);
      }
    }
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      final className = ctx.events[name];
      if (className != null) result.add(className);
    }
    for (final child in node.childEntities) {
      if (child is AstNode) collectWrites(child);
    }
  }

  for (final stmt in stmts) {
    collectWrites(stmt);
  }

  // Also scan private helpers.
  final helpers = collectPrivateHelpers(stmts, unit);
  for (final helperName in helpers) {
    for (final decl in unit.declarations) {
      if (decl is FunctionDeclaration && decl.name.lexeme == helperName) {
        final body = decl.functionExpression.body;
        if (body is BlockFunctionBody) {
          for (final stmt in body.block.statements) {
            collectWrites(stmt);
          }
        }
        break;
      }
    }
  }

  return result;
}

/// Emits a private helper function from [unit] as a private method string,
/// with its body transformed by [ctx].
String emitPrivateMethod(String name, CompilationUnit unit, DslContext ctx) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == name) {
      final func = decl.functionExpression;
      final returnType = decl.returnType?.toSource() ?? 'void';
      final params = func.parameters?.toSource() ?? '()';
      final body = func.body;
      if (body is BlockFunctionBody) {
        final transformed = transformDslStatements(body.block.statements, ctx);
        final buffer = StringBuffer();
        buffer.writeln('  $returnType $name$params {');
        buffer.write(transformed);
        buffer.writeln('  }');
        return buffer.toString();
      }
    }
  }
  return '';
}
