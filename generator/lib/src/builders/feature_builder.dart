import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import '../models/manager_model.dart';
import '../visitors/entity_visitor.dart';
import '../visitors/feature_visitor.dart';
import '../visitors/system_visitor.dart';

final class FeatureBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.ecs.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    final source = await buildStep.readAsString(inputId);
    if (!source.contains('.ecs.g.dart')) return;

    if (!await buildStep.resolver.isLibrary(inputId)) return;

    final fragmentUnit =
        await buildStep.resolver.astNodeFor((await buildStep.resolver.libraryFor(inputId)).firstFragment, resolve: false) as CompilationUnit?;

    final hasEcsPart = fragmentUnit?.directives.whereType<PartDirective>().any((d) => d.uri.stringValue?.endsWith('.ecs.g.dart') ?? false) ?? false;

    if (!hasEcsPart) return;

    final library = await buildStep.resolver.libraryFor(inputId);
    final manager = ManagerModel();

    await _scanImports(library, manager, buildStep);

    final importedKeys = manager.features.keys.toSet();

    final unit = await buildStep.resolver.astNodeFor(
      library.firstFragment,
      resolve: true,
    ) as CompilationUnit?;
    if (unit == null) return;

    unit.accept(FeatureVisitor(manager));
    unit.accept(EntityVisitor(manager));
    unit.accept(SystemVisitor(manager));

    final localFeatures = manager.features.entries.where((e) => !importedKeys.contains(e.key)).map((e) => e.value).toList();

    if (localFeatures.isEmpty) return;
    if (localFeatures.length != 1) {
      log.warning('Expected exactly one feature per file in ${inputId.path}');
      return;
    }

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln("part of '${inputId.pathSegments.last}';")
      ..writeln();

    for (final feature in localFeatures) {
      buffer
        ..writeln(feature.generate())
        ..writeln();
    }

    final formatted = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion, pageWidth: 120).format(buffer.toString());

    await buildStep.writeAsString(inputId.changeExtension('.ecs.g.dart'), formatted);
  }

  Future<void> _scanImports(LibraryElement root, ManagerModel manager, BuildStep buildStep) async {
    final visited = <LibraryElement>{root};
    final queue = Queue<LibraryElement>();

    for (final import in root.firstFragment.libraryImports) {
      final lib = import.importedLibrary;
      if (lib != null && !lib.isInSdk) queue.add(lib);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!visited.add(current)) continue;

      final importedUnit = await buildStep.resolver.astNodeFor(
        current.firstFragment,
        resolve: true,
      ) as CompilationUnit?;

      if (importedUnit != null) {
        importedUnit.accept(FeatureVisitor(manager));
        importedUnit.accept(EntityVisitor(manager));
      }

      for (final import in current.firstFragment.libraryImports) {
        final next = import.importedLibrary;
        if (next != null && !next.isInSdk && !visited.contains(next)) {
          queue.add(next);
        }
      }
    }
  }
}
