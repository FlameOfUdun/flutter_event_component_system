import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'widgets/ecs_entity_browser.dart';
import 'widgets/ecs_event_provider.dart';
import 'widgets/ecs_graph_view.dart';
import 'widgets/ecs_log_viewer.dart';

void main() {
  runApp(DevToolsExtension(child: ECSEventProvider(child: const _Application())));
}

class _Application extends StatefulWidget {
  const _Application();

  @override
  State<_Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<_Application> {
  var selectedTab = 'graph_view';

  @override
  Widget build(BuildContext context) {
    final provider = ECSEventProvider.of(context);

    return Scaffold(
      body: FutureBuilder(
        future: provider.waitForServiceInit(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                children: [Text('Initializing ECS Inspector...'), CircularProgressIndicator()],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error initializing ECS Inspector: ${snapshot.error}'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                child: SegmentedButton(
                  segments: const [
                    ButtonSegment(value: 'graph_view', label: Text('Graph View')),
                    ButtonSegment(value: 'entity_browser', label: Text('Entity Browser')),
                    ButtonSegment(value: 'log_viewer', label: Text('Log Viewer')),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (values) {
                    setState(() {
                      selectedTab = values.first;
                    });
                  },
                ),
              ),
              Expanded(
                child: switch (selectedTab) {
                  'graph_view' => const ECSGraphView(),
                  'entity_browser' => const ECSEntityBrowser(),
                  'log_viewer' => const ECSLogViewer(),
                  _ => throw UnimplementedError(),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
