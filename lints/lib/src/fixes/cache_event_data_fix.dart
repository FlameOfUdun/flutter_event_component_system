import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Quick fix that caches ECSDataEvent.data before the async gap.
class CacheEventDataFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    // Handle PropertyAccess: event.data
    context.registry.addPropertyAccess((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;
      if (node.propertyName.name != 'data') return;

      _createFix(
        resolver: resolver,
        reporter: reporter,
        dataAccessNode: node,
        targetSource: node.target?.toSource() ?? 'event',
      );
    });

    // Handle PrefixedIdentifier: event.data (simple identifier form)
    context.registry.addPrefixedIdentifier((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;
      if (node.identifier.name != 'data') return;

      _createFix(
        resolver: resolver,
        reporter: reporter,
        dataAccessNode: node,
        targetSource: node.prefix.toSource(),
      );
    });
  }

  void _createFix({
    required CustomLintResolver resolver,
    required ChangeReporter reporter,
    required AstNode dataAccessNode,
    required String targetSource,
  }) {
    final body = dataAccessNode.thisOrAncestorOfType<BlockFunctionBody>();
    if (body == null || !body.isAsynchronous) return;

    final firstAwaitStmt = _firstStatementWithAwait(body.block);
    if (firstAwaitStmt == null) return;

    final varName = _generateVarName(targetSource);
    final indent = _indent(firstAwaitStmt, resolver);

    final changeBuilder = reporter.createChangeBuilder(
      message: "Cache '$varName' before async gap",
      priority: 80,
    );

    changeBuilder.addDartFileEdit((builder) {
      // Insert cache statement before first await
      builder.addSimpleInsertion(
        firstAwaitStmt.offset,
        'final $varName = $targetSource.data;\n$indent',
      );
      // Replace the data access with the cached variable
      builder.addSimpleReplacement(range.node(dataAccessNode), varName);
    });
  }

  Statement? _firstStatementWithAwait(Block block) {
    for (final stmt in block.statements) {
      final finder = _AwaitFinder();
      stmt.accept(finder);
      if (finder.found) return stmt;
    }
    return null;
  }

  String _generateVarName(String targetSource) {
    // Convert "getEntity<LoginEvent>()" or "loginEvent" to "loginEventData"
    final cleaned = targetSource
        .replaceAll(RegExp(r'getEntity<(\w+)>\(\)'), r'$1')
        .replaceAll(RegExp(r'[<>()]'), '');

    if (cleaned.isEmpty) return 'eventData';

    // Ensure camelCase and append 'Data'
    final base = cleaned[0].toLowerCase() + cleaned.substring(1);
    return '${base}Data';
  }

  String _indent(Statement stmt, CustomLintResolver resolver) {
    final source = resolver.source.contents.data;
    var i = stmt.offset - 1;
    while (i >= 0 && source[i] != '\n') {
      i--;
    }
    final buf = StringBuffer();
    for (var j = i + 1; j < stmt.offset; j++) {
      if (source[j] == ' ' || source[j] == '\t') {
        buf.write(source[j]);
      } else {
        break;
      }
    }
    return buf.toString();
  }
}

class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }
}
