import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/cache_event_data_fix.dart';

/// Lint rule that flags accessing `.data` on `ECSDataEvent` instances
/// after an `await` expression, since the data gets nullified after
/// notifying listeners.
final class NoEventDataAcrossAsyncGap extends DartLintRule {
  const NoEventDataAcrossAsyncGap() : super(code: _code);

  static const _code = LintCode(
    name: 'no_event_data_across_async_gap',
    problemMessage: "Don't access ECSDataEvent.data after an async gap. "
        "The data is nullified immediately after notifying listeners.",
    correctionMessage: 'Capture the data in a local variable before the first await.',
  );

  @override
  List<Fix> getFixes() => [CacheEventDataFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionBody((body) {
      if (!body.isAsynchronous) return;
      body.accept(_EventDataGapVisitor(reporter, _code));
    });
  }
}

class _EventDataGapVisitor extends RecursiveAstVisitor<void> {
  _EventDataGapVisitor(this._reporter, this._code);

  final DiagnosticReporter _reporter;
  final LintCode _code;
  bool _pastGap = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _pastGap = true;
    super.visitAwaitExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_pastGap && _isDataOnECSDataEvent(node)) {
      _reporter.atNode(node, _code);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_pastGap && _isDataOnECSDataEventPrefixed(node)) {
      _reporter.atNode(node, _code);
    }
    super.visitPrefixedIdentifier(node);
  }

  bool _isDataOnECSDataEvent(PropertyAccess node) {
    if (node.propertyName.name != 'data') return false;
    final targetType = node.target?.staticType;
    return _extendsECSDataEvent(targetType);
  }

  bool _isDataOnECSDataEventPrefixed(PrefixedIdentifier node) {
    if (node.identifier.name != 'data') return false;
    final targetType = node.prefix.staticType;
    return _extendsECSDataEvent(targetType);
  }

  bool _extendsECSDataEvent(DartType? type) {
    if (type == null || type is! InterfaceType) return false;

    final element = type.element;
    if (element is! ClassElement) return false;

    // Check if the class itself is ECSDataEvent or extends it
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
}
