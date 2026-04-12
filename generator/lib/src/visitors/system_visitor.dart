import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import '../models/manager_model.dart';
import '../models/system_model.dart';

final class SystemVisitor extends RecursiveAstVisitor<void> {
  final ManagerModel manager;
  final Map<String, FunctionDeclaration> _functions = {};

  SystemVisitor(this.manager);

  static const _supportedMethods = {
    'addReactiveSystem',
    'addExecuteSystem',
    'addCleanupSystem',
    'addTeardownSystem',
    'addInitializeSystem',
  };

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final decl in node.declarations) {
      if (decl is FunctionDeclaration) {
        _functions[decl.name.lexeme] = decl;
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element is! VariableElement) {
      super.visitVariableDeclaration(node);
      return;
    }

    final init = node.initializer;
    if (init is! MethodInvocation || !_supportedMethods.contains(init.methodName.name)) {
      super.visitVariableDeclaration(node);
      return;
    }

    final featureElement = extractVariable(init.target);
    if (featureElement == null) {
      super.visitVariableDeclaration(node);
      return;
    }
    final feature = manager.getFeature(featureElement);
    if (feature == null) {
      super.visitVariableDeclaration(node);
      return;
    }

    final system = _buildSystem(node.name.lexeme, element, init);
    if (system != null) {
      system.feature = feature;
      feature.addSystem(system);
    }

    super.visitVariableDeclaration(node);
  }

  SystemModel? _buildSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    return switch (init.methodName.name) {
      'addReactiveSystem' => _handleReactiveSystem(name, element, init),
      'addExecuteSystem' => _handleExecuteSystem(name, element, init),
      'addCleanupSystem' => _handleCleanupSystem(name, element, init),
      'addTeardownSystem' => _handleTeardownSystem(name, element, init),
      'addInitializeSystem' => _handleInitializeSystem(name, element, init),
      _ => null,
    };
  }

  ReactiveSystemModel _handleReactiveSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    final args = _namedArgMap(init);

    final reactExpr = args['react'];
    if (reactExpr is! FunctionExpression) {
      throw StateError(
        'addReactiveSystem("$name"): "react" must be a function literal.',
      );
    }

    final reactsIfExpr = args['reactsIf'];

    return ReactiveSystemModel(
      name: name,
      reactsTo: _extractReactsTo(args['reactsTo']),
      react: reactExpr.body,
      reactsIf: reactsIfExpr is FunctionExpression ? reactsIfExpr.body : null,
      helpers: [
        ..._resolveHelpers(reactExpr.body),
        if (reactsIfExpr is FunctionExpression) ..._resolveHelpers(reactsIfExpr.body),
      ],
    );
  }

  ExecuteSystemModel? _handleExecuteSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    final args = _namedArgMap(init);

    final executeExpr = args['execute'];
    if (executeExpr is! FunctionExpression) {
      throw StateError(
        'addExecuteSystem("$name"): "execute" must be a function literal.',
      );
    }

    final executesIfExpr = args['executesIf'];

    return ExecuteSystemModel(
      name: name,
      execute: executeExpr.body,
      executesIf: executesIfExpr is FunctionExpression ? executesIfExpr.body : null,
      helpers: [
        ..._resolveHelpers(executeExpr.body),
        if (executesIfExpr is FunctionExpression) ..._resolveHelpers(executesIfExpr.body),
      ],
    );
  }

  CleanupSystemModel? _handleCleanupSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    final args = _namedArgMap(init);

    final cleanupExpr = args['cleanup'];
    if (cleanupExpr is! FunctionExpression) {
      throw StateError(
        'addCleanupSystem("$name"): "cleanup" must be a function literal.',
      );
    }

    final cleansIfExpr = args['cleansIf'];

    return CleanupSystemModel(
      name: name,
      cleanup: cleanupExpr.body,
      cleansIf: cleansIfExpr is FunctionExpression ? cleansIfExpr.body : null,
      helpers: [
        ..._resolveHelpers(cleanupExpr.body),
        if (cleansIfExpr is FunctionExpression) ..._resolveHelpers(cleansIfExpr.body),
      ],
    );
  }

  TeardownSystemModel? _handleTeardownSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    final args = _namedArgMap(init);

    final teardownExpr = args['teardown'];
    if (teardownExpr is! FunctionExpression) {
      throw StateError(
        'addTeardownSystem("$name"): "teardown" must be a function literal.',
      );
    }

    final teardownsIfExpr = args['teardownsIf'];

    return TeardownSystemModel(
      name: name,
      teardown: teardownExpr.body,
      helpers: [
        ..._resolveHelpers(teardownExpr.body),
        if (teardownsIfExpr is FunctionExpression) ..._resolveHelpers(teardownsIfExpr.body),
      ],
    );
  }

  InitializeSystemModel? _handleInitializeSystem(
    String name,
    VariableElement element,
    MethodInvocation init,
  ) {
    final args = _namedArgMap(init);

    final initializeExpr = args['initialize'];
    if (initializeExpr is! FunctionExpression) {
      throw StateError(
        'addInitializeSystem("$name"): "initialize" must be a function literal.',
      );
    }

    final initializesIfExpr = args['initializesIf'];

    return InitializeSystemModel(
      name: name,
      initialize: initializeExpr.body,
      helpers: [
        ..._resolveHelpers(initializeExpr.body),
        if (initializesIfExpr is FunctionExpression) ..._resolveHelpers(initializesIfExpr.body),
      ],
    );
  }

  List<FunctionDeclaration> _resolveHelpers(FunctionBody body) {
    final local = _extractLocalHelpers(body);
    final resolved = <String, FunctionDeclaration>{};
    final queue = <FunctionBody>[body];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();

      final calledNames = <String>{};
      current.accept(_BareFunctionCallCollector(calledNames));

      for (final name in calledNames) {
        if (_functions.containsKey(name) && !resolved.containsKey(name)) {
          final decl = _functions[name]!;
          resolved[name] = decl;
          queue.add(decl.functionExpression.body);
        }
      }
    }

    return [...local, ...resolved.values];
  }

  Map<String, Expression> _namedArgMap(MethodInvocation init) {
    final map = <String, Expression>{};
    for (final arg in init.argumentList.arguments) {
      if (arg is NamedExpression) {
        map[arg.name.label.name] = arg.expression;
      }
    }
    return map;
  }

  Set<VariableElement> _extractReactsTo(Expression? expr) {
    if (expr == null) return {};
    final elements = <VariableElement>{};

    final collectionElements = switch (expr) {
      SetOrMapLiteral() => expr.elements,
      ListLiteral() => expr.elements,
      _ => null,
    };

    if (collectionElements != null) {
      for (final el in collectionElements) {
        final variable = switch (el) {
          SimpleIdentifier() => resolveToVariable(el.element),
          PrefixedIdentifier() => resolveToVariable(el.identifier.element),
          _ => null,
        };
        if (variable != null) elements.add(variable);
      }
    } else {
      final v = extractVariable(expr);
      if (v != null) elements.add(v);
    }

    return elements;
  }

  List<FunctionDeclaration> _extractLocalHelpers(FunctionBody body) {
    if (body is! BlockFunctionBody) return const [];
    return body.block.statements.whereType<FunctionDeclarationStatement>().map((s) => s.functionDeclaration).toList();
  }
}

final class _BareFunctionCallCollector extends RecursiveAstVisitor<void> {
  final Set<String> names;
  _BareFunctionCallCollector(this.names);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      names.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      names.add(node.name);
    }
    super.visitSimpleIdentifier(node);
  }
}
