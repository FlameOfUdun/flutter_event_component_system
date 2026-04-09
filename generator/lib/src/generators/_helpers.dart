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

// Helper to compute a safe relative range for [node] against [baseOffset].
(int, int) _relRangeNode(AstNode node, int baseOffset, int maxLen) {
  final rawStart = node.offset - baseOffset;
  final rawEnd = node.end - baseOffset;
  final s = rawStart.clamp(0, maxLen);
  final e = rawEnd.clamp(0, maxLen);
  return (s, e);
}

/// Holds entity maps for DSL rewriting within a single source file.
class DslContext {
  /// varName → component class name, e.g. "health" → "HealthComponent"
  final Map<String, String> components;

  /// funcName → event class name, e.g. "logout" → "LogoutEvent"
  final Map<String, String> events;

  /// varName → dependency class name, e.g. "authRepo" → "AuthRepoDependency"
  final Map<String, String> dependencies;

  /// paramName → replacement expression, e.g. "amount" → "getEntity&lt;AddHealthEvent&gt;().data"
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
    // Explicitly handle try/catch/finally blocks by visiting their inner bodies
    // rather than using the catch/clause header offsets which may not align
    // with the statement's `toSource()` string. This avoids out-of-range
    // replacement indices for complex blocks.
    if (node is TryStatement) {
      visit(node.body);
      for (final c in node.catchClauses) {
        visit(c.body);
      }
      if (node.finallyBlock != null) visit(node.finallyBlock!);
      return;
    }
    if (node is SimpleIdentifier) {
      final name = node.name;
      // Skip if this is a method name.
      if (node.parent is MethodInvocation && (node.parent as MethodInvocation).methodName == node) {
        return;
      }
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        final (s, e) = _relRangeNode(node, expr.offset, source.length);
        replacements.add((s, e, paramReplacement));
        return;
      }
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        final (s, e) = _relRangeNode(node, expr.offset, source.length);
        replacements.add((s, e, 'getEntity<$className>().value'));
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
///   - Component/dependency reads: `health` → `getEntity<HealthComponent>().value` (only when [rewriteReads] is true)
String transformDslStatement(Statement stmt, DslContext ctx, {bool rewriteReads = false}) {
  final source = stmt.toSource();
  final replacements = <(int start, int end, String text)>[];

  // Special-case TryStatement: transform inner blocks separately to avoid
  // offset/alignment issues when performing substring replacements on the
  // entire try/catch/finally source.
  if (stmt is TryStatement) {
    final buffer = StringBuffer();
    buffer.writeln('try {');
    buffer.write(transformDslStatements(stmt.body.statements, ctx, rewriteReads: rewriteReads));
    buffer.writeln('  }');
    for (final c in stmt.catchClauses) {
      final oldBody = c.body.toSource();
      final newBody = '{\n${transformDslStatements((c.body).statements, ctx, rewriteReads: rewriteReads)}  }';
      final catchSrc = c.toSource().replaceFirst(oldBody, newBody);
      buffer.writeln(catchSrc);
    }
    if (stmt.finallyBlock != null) {
      final newBody = '{\n${transformDslStatements((stmt.finallyBlock!).statements, ctx, rewriteReads: rewriteReads)}  }';
      buffer.writeln(' finally $newBody');
    }
    return buffer.toString();
  }

  void visit(AstNode node) {
    // Assignment expression: rewrite lhs only, let rhs be visited normally.
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        final name = lhs.name;
        final className = ctx.components[name] ?? ctx.dependencies[name];
        if (className != null) {
          final (s, e) = _relRangeNode(lhs, stmt.offset, source.length);
          replacements.add((s, e, 'getEntity<$className>().value'));
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
        final (s, e) = _relRangeNode(node, stmt.offset, source.length);
        if (args.isEmpty) {
          replacements.add((s, e, 'getEntity<$className>().trigger()'));
        } else {
          final transformedArgs = args.map((a) => _transformExpr(a, ctx)).join(', ');
          replacements.add((s, e, 'getEntity<$className>().trigger($transformedArgs)'));
        }
        return;
      }
    }

    // Simple identifier: param replacement, and optionally component reads.
    if (node is SimpleIdentifier) {
      final name = node.name;
      // Skip if this is a method name in an invocation.
      if (node.parent is MethodInvocation && (node.parent as MethodInvocation).methodName == node) {
        return;
      }
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        final (s, e) = _relRangeNode(node, stmt.offset, source.length);
        replacements.add((s, e, paramReplacement));
        return;
      }
      if (rewriteReads) {
        final className = ctx.components[name] ?? ctx.dependencies[name];
        if (className != null) {
          final (s, e) = _relRangeNode(node, stmt.offset, source.length);
          replacements.add((s, e, 'getEntity<$className>().value'));
          return;
        }
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
    // Bounds check to prevent RangeError
    if (start < 0 || end > source.length || start > end) {
      throw InvalidGenerationSourceError(
        'transformDslStatement: Replacement indices out of bounds: '
        'start=$start, end=$end, source.length=${source.length}\n'
        'Source: $source',
      );
    }
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a list of statements, indenting each by 4 spaces.
String transformDslStatements(NodeList<Statement> stmts, DslContext ctx, {bool rewriteReads = false}) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformDslStatement(stmt, ctx, rewriteReads: rewriteReads)}');
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
        final transformed = transformDslStatements(body.block.statements, ctx, rewriteReads: true);
        final modifier = '${body.keyword?.lexeme ?? ''}${body.star?.lexeme ?? ''}';
        final asyncStr = modifier.isNotEmpty ? ' $modifier' : '';
        final buffer = StringBuffer();
        buffer.writeln('  $returnType $name$params$asyncStr {');
        buffer.write(transformed);
        buffer.writeln('  }');
        return buffer.toString();
      }
    }
  }
  return '';
}
