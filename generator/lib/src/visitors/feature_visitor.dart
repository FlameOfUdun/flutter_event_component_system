import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import '../models/feature_model.dart';
import '../models/manager_model.dart';

final class FeatureVisitor extends RecursiveAstVisitor<void> {
  final ManagerModel manager;

  FeatureVisitor(this.manager);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final init = node.initializer;

    if (init is! MethodInvocation) return;

    if (init.methodName.name != 'createFeature') return;

    final target = init.target;

    final classElement = extractClass(target);

    if (classElement == null || classElement.name != 'ECS') {
      return;
    }

    final element = node.declaredFragment?.element;
    if (element is! VariableElement) return;

    manager.addFeature(FeatureModel(name: node.name.lexeme, element: element));
  }
}
