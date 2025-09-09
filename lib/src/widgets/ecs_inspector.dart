part of '../ecs_base.dart';

final class ECSInspector extends StatefulWidget {
  final Duration refreshDelay;

  const ECSInspector({super.key, this.refreshDelay = const Duration(milliseconds: 100)});

  @override
  State<ECSInspector> createState() => _ECSInspectorState();
}

final class _ECSInspectorState extends State<ECSInspector> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(widget.refreshDelay, (timer) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'Entities'),
              Tab(text: 'Logs'),
              Tab(text: 'Graph'),
            ],
          ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SummaryView(),
                  _EntitiesView(),
                  _LogsView(),
                  _GraphView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryView extends StatefulWidget {
  const _SummaryView();

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

final class _SummaryViewState extends State<_SummaryView> {
  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final analysis = ECSAnalyzer.analize(manager);
    final cascade = analysis.getCascadeAnalysis();

    return ListView(
      children: [for (final line in cascade) Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0), child: Text(line))],
    );
  }
}

final class _EntitiesView extends StatefulWidget {
  const _EntitiesView();

  @override
  State<_EntitiesView> createState() => _EntitiesViewState();
}

final class _EntitiesViewState extends State<_EntitiesView> {
  final controller = TextEditingController();

  String? type;
  String? feature;

  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final entities = manager.entities;
    final features = manager.features;

    final filtered = entities.where((entity) {
      if (controller.text.isNotEmpty) {
        final text = controller.text.toLowerCase();
        final match = entity.toString().toLowerCase().contains(text);
        if (!match) return false;
      }

      if (type != null) {
        if (type == 'event') return entity is ECSEvent;
        if (type == 'component') return entity is ECSComponent;
      }

      if (feature != null) {
        return entity.parent.runtimeType.toString() == feature!;
      }

      return true;
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('No entities found'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                  itemBuilder: (context, index) {
                    final entity = filtered.elementAt(index);

                    if (entity is ECSEvent) {
                      return ListTile(
                        title: Text('${entity.parent.runtimeType}.${entity.runtimeType}'),
                        trailing: IconButton(onPressed: entity.trigger, icon: const Icon(Icons.play_arrow)),
                      );
                    }
                    return ExpansionTile(
                      title: Text('${entity.parent.runtimeType}.${entity.runtimeType}'),
                      childrenPadding: const EdgeInsets.all(8),
                      expandedAlignment: Alignment.centerLeft,
                      children: [entity.buildInspector(context)],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: feature,
                    decoration: const InputDecoration(labelText: 'Feature', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final feature in features)
                        DropdownMenuItem(value: feature.runtimeType.toString(), child: Text(feature.runtimeType.toString())),
                    ],
                    onChanged: (value) {
                      setState(() {
                        feature = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'event', child: Text('Event')),
                      DropdownMenuItem(value: 'component', child: Text('Component')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        type = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      labelText: 'Search',
                      border: const OutlineInputBorder(),
                      suffix: IconButton(icon: const Icon(Icons.clear), onPressed: controller.clear),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _LogsView extends StatefulWidget {
  const _LogsView();

  @override
  State<_LogsView> createState() => _LogsViewState();
}

final class _LogsViewState extends State<_LogsView> {
  final controller = TextEditingController();
  ECSLogLevel? level;

  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ECSLogger.entries.reversed;

    final filtered = entries.where((entry) {
      if (level != null && entry.level != level) return false;
      if (controller.text.isEmpty) return true;
      return entry.description.toLowerCase().contains(controller.text.toLowerCase());
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('No logs found'));
                }

                return ListView.separated(
                  reverse: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered.elementAt(index);
                    return ExpansionTile(
                      title: Text('${log.level.name.toUpperCase()} - ${log.time}'),
                      subtitle: Text(log.description),
                      childrenPadding: const EdgeInsets.all(8.0),
                      children: [
                        const Row(children: [Text('Call Stack:')]),
                        SelectableText(log.stack.toString()),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: level,
                    decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                    items: ECSLogLevel.values.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level.name.toUpperCase()));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        level = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      labelText: 'Search',
                      border: const OutlineInputBorder(),
                      suffix: IconButton(icon: const Icon(Icons.clear), onPressed: controller.clear),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      ECSLogger.clear();
                    });
                  },
                  icon: const Icon(Icons.delete),
                  tooltip: 'Clear Logs',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _GraphView extends StatefulWidget {
  const _GraphView();

  @override
  State<_GraphView> createState() => _GraphViewState();
}

final class _GraphViewState extends State<_GraphView> {
  InAppWebViewController? controller;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialFile: "packages/flutter_event_component_system/assets/ecs_graph.html",
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowsInlineMediaPlayback: true,
      ),
      onWebViewCreated: (webViewController) {
        controller = webViewController;
      },
      onLoadStop: (webViewController, url) {
        if (controller == null) return;
        final manager = ECSScope.of(context);
        final analysis = ECSAnalyzer.analize(manager);
        final graph = analysis.generateDotGraph();
        controller!.evaluateJavascript(source: '''
      window.updateGraph(`${graph.replaceAll('`', '\\`')}`);
    ''');
      },
    );
  }
}
