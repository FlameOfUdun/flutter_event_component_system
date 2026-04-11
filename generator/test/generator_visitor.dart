import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:flutter_event_component_system_generator/src/models/manager_model.dart';
import 'package:flutter_event_component_system_generator/src/visitors/entity_visitor.dart';
import 'package:flutter_event_component_system_generator/src/visitors/feature_visitor.dart';
import 'package:flutter_event_component_system_generator/src/visitors/system_visitor.dart';
import 'package:test/test.dart';

void main() {
  test("Test", () async {
    final filePath = '${Directory.current.path}\\test\\test_file.dart';
    final collection = AnalysisContextCollection(includedPaths: [filePath]);
    final context = collection.contextFor(filePath);
    final session = context.currentSession;
    final resolved = await session.getResolvedUnit(filePath) as ResolvedUnitResult;

    final manager = ManagerModel();
    resolved.unit.accept(FeatureVisitor(manager));
    resolved.unit.accept(EntityVisitor(manager));
    resolved.unit.accept(SystemVisitor(manager));

    for (final feature in manager.features.values) {
      print(feature.generate());
    }
  });
}
