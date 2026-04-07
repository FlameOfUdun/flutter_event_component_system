import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rewrites `system.getX(varName)` calls in a raw source string to
/// the generated `getEntity<XClassName>()` form.
String transformSource(String source) {
  source = source.replaceAllMapped(
    RegExp(r'system\.getComponent\((\w+)\)'),
    (m) => 'getEntity<${capitalize(m.group(1)!)}Component>()',
  );
  source = source.replaceAllMapped(
    RegExp(r'system\.getDataEvent\((\w+)\)'),
    (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
  );
  source = source.replaceAllMapped(
    RegExp(r'system\.getEvent\((\w+)\)'),
    (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
  );
  source = source.replaceAllMapped(
    RegExp(r'system\.getDependency\((\w+)\)'),
    (m) => 'getEntity<${capitalize(m.group(1)!)}Dependency>()',
  );
  return source;
}

/// Transforms a list of statements, indenting each by 4 spaces and
/// applying [transformSource] to each statement's source text.
String transformStatements(NodeList<Statement> stmts) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformSource(stmt.toSource())}');
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
