import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'widgets/ecs_entity_browser.dart';
import 'widgets/ecs_event_provider.dart';
import 'widgets/ecs_graph_view.dart';
import 'widgets/ecs_log_viewer.dart';

void main() => runApp(DevToolsExtension(child: ECSEventProvider(child: const _Application())));

class _Application extends StatelessWidget {
  const _Application();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Graph View'),
                Tab(text: 'Entity Browser'),
                Tab(text: 'Log Viewer'),
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  ECSGraphView(),
                  ECSEntityBrowser(),
                  ECSLogViewer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
