import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../helpers.dart';
import '../models/entity_model.dart';
import '../models/manager_model.dart';

final class EntityVisitor extends RecursiveAstVisitor<void> {
  final ManagerModel manager;

  EntityVisitor(this.manager);

  static const _supportedMethods = {
    'addComponent',
    'addEvent',
    'addDataEvent',
    'addDependency',
  };

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

    final entity = _buildEntity(node.name.lexeme, element, init);
    if (entity != null) {
      feature.addEntity(entity);
    }

    super.visitVariableDeclaration(node);
  }

  EntityModel? _buildEntity(String name, VariableElement element, MethodInvocation init) {
    return switch (init.methodName.name) {
      'addComponent' => _buildComponent(name, element, init),
      'addEvent' => _buildEvent(name, element),
      'addDataEvent' => _buildDataEvent(name, element, init),
      'addDependency' => _buildDependency(name, element, init),
      _ => null,
    };
  }

  EventModel _buildEvent(String name, VariableElement element) {
    return EventModel(name: name, element: element);
  }

  ComponentModel? _buildComponent(String name, VariableElement element, MethodInvocation init) {
    final type = _resolveTypeString(element, init);
    final args = init.argumentList.arguments;
    return ComponentModel(
      name: name,
      element: element,
      type: type,
      value: args.isNotEmpty ? args.first.toSource() : null,
    );
  }

  DataEventModel? _buildDataEvent(String name, VariableElement element, MethodInvocation init) {
    final type = _resolveTypeString(element, init);
    return DataEventModel(
      name: name,
      element: element,
      type: type,
    );
  }

  DependencyModel? _buildDependency(String name, VariableElement element, MethodInvocation init) {
    final type = _resolveTypeString(element, init);
    final args = init.argumentList.arguments;
    return DependencyModel(
      name: name,
      element: element,
      type: type,
      value: args.isNotEmpty ? args.first.toSource() : null,
    );
  }

  String? _resolveTypeString(VariableElement element, MethodInvocation init) {
    final explicitArgs = init.typeArguments?.arguments;
    if (explicitArgs != null && explicitArgs.isNotEmpty) {
      return explicitArgs.first.type?.getDisplayString();
    }

    final varType = element.type;
    if (varType is ParameterizedType && varType.typeArguments.isNotEmpty) {
      return varType.typeArguments.first.getDisplayString();
    }

    return null;
  }
}
