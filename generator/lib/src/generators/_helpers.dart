import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rewrites all `system.getX(varName)` method invocations in [stmt] to
/// `getEntity<XClassName>()` using AST offsets. Handles any whitespace
/// formatting and multiline calls correctly.
String transformStatement(Statement stmt) {
  final source = stmt.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    if (node is MethodInvocation) {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'system') {
        final method = node.methodName.name;
        final args = node.argumentList.arguments;
        if (args.length == 1 && args.first is SimpleIdentifier) {
          final argName = (args.first as SimpleIdentifier).name;
          final suffix = switch (method) {
            'getComponent' => 'Component',
            'getDataEvent' => 'Event',
            'getEvent' => 'Event',
            'getDependency' => 'Dependency',
            _ => null,
          };
          if (suffix != null) {
            final relStart = node.offset - stmt.offset;
            final relEnd = node.end - stmt.offset;
            replacements.add((relStart, relEnd, 'getEntity<${capitalize(argName)}$suffix>()'));
          }
        }
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(stmt);

  if (replacements.isEmpty) return source;

  // Apply back-to-front so earlier offsets remain valid after each splice.
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a list of statements, indenting each by 4 spaces and
/// applying [transformStatement] to rewrite `system.getX()` calls.
String transformStatements(NodeList<Statement> stmts) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformStatement(stmt)}');
  }
  return buffer.toString();
}

/// Validates that [body] is a block body and returns [transformStatements]
/// applied to its statements. Throws [InvalidGenerationSourceError] otherwise.
String extractBlockBody(FunctionBody body, Element element) {
  if (body is! BlockFunctionBody) {
    throw InvalidGenerationSourceError(
      'System function must use a block body {}. Expression bodies => are not supported.',
      element: element,
    );
  }
  return transformStatements(body.block.statements);
}

/// Returns the name of the top-level function referenced by the named
/// annotation parameter [param], or null if absent.
String? extractFuncRef(FunctionDeclaration funcDecl, String param) {
  for (final ann in funcDecl.metadata) {
    for (final arg in ann.arguments?.arguments ?? <Expression>[]) {
      if (arg is NamedExpression && arg.name.label.name == param) {
        if (arg.expression is SimpleIdentifier) {
          return (arg.expression as SimpleIdentifier).name;
        }
      }
    }
  }
  return null;
}

/// Finds a top-level function named [name] in [unit] and returns the
/// transformed body text, or null if not found.
String? extractNamedFuncBody(String name, CompilationUnit unit) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == name) {
      final body = decl.functionExpression.body;
      if (body is BlockFunctionBody) {
        return transformStatements(body.block.statements);
      }
    }
  }
  return null;
}

/// Returns the Dart source literal for the constant default value of [element].
/// Handles String, int, double, and bool. Returns `'null'` for other types.
String extractDefault(TopLevelVariableElement element) {
  final constant = element.computeConstantValue()!;
  final type = element.type;
  if (type.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
  if (type.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
  if (type.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
  if (type.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
  return 'null';
}
