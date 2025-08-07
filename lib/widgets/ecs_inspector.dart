part of '../flutter_event_component_system.dart';

class ECSInspector extends StatefulWidget {
  final Duration refreshDelay;

  const ECSInspector({
    super.key,
    this.refreshDelay = const Duration(milliseconds: 100),
  });

  @override
  State<ECSInspector> createState() => _ECSInspectorState();
}

class _ECSInspectorState extends State<ECSInspector> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(
      widget.refreshDelay,
      (timer) {
        if (!mounted) return;
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ECS Inspector'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'Entities'),
                Tab(text: 'Logs'),
                Tab(text: 'Graph'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _SummaryView(),
              _EntitiesView(),
              _LogsView(),
              _GraphView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends StatefulWidget {
  const _SummaryView();

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<_SummaryView> {
  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final analysis = ECSAnalyzer.analize(manager);
    final cascade = analysis.getCascadeAnalysis();

    return ListView(
      children: [
        for (final line in cascade)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 2.0,
            ),
            child: Text(line),
          ),
      ],
    );
  }
}

class _EntitiesView extends StatefulWidget {
  const _EntitiesView();

  @override
  State<_EntitiesView> createState() => _EntitiesViewState();
}

class _EntitiesViewState extends State<_EntitiesView> {
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
                  return const Center(
                    child: Text('No entities found'),
                  );
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
                        trailing: IconButton(
                          onPressed: entity.trigger,
                          icon: Icon(Icons.play_arrow),
                        ),
                      );
                    }
                    return ExpansionTile(
                      title: Text('${entity.parent.runtimeType}.${entity.runtimeType}'),
                      childrenPadding: const EdgeInsets.all(8),
                      expandedAlignment: Alignment.centerLeft,
                      children: [
                        entity.buildInspector(context),
                      ],
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
                    decoration: const InputDecoration(
                      labelText: 'Feature',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      for (final feature in features)
                        DropdownMenuItem(
                          value: feature.runtimeType.toString(),
                          child: Text(feature.runtimeType.toString()),
                        ),
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
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      const DropdownMenuItem(
                        value: 'event',
                        child: Text('Event'),
                      ),
                      const DropdownMenuItem(
                        value: 'component',
                        child: Text('Component'),
                      ),
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
                      border: OutlineInputBorder(),
                      suffix: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clear,
                      ),
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

class _LogsView extends StatefulWidget {
  const _LogsView();

  @override
  State<_LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<_LogsView> {
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
            child: Builder(builder: (context) {
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No logs found'),
                );
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
                      Row(
                        children: [
                          Text('Call Stack:'),
                        ],
                      ),
                      SelectableText(
                        log.stack.toString(),
                      ),
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 0);
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: level,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                    ),
                    items: ECSLogLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level.name.toUpperCase()),
                      );
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
                      border: OutlineInputBorder(),
                      suffix: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: controller.clear,
                      ),
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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphView extends StatefulWidget {
  const _GraphView();

  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView> {
  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final analysis = ECSAnalyzer.analize(manager);
    final graph = analysis.generateDotGraph();

    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
        <script src="https://cdn.jsdelivr.net/npm/viz.js@2.1.2/viz.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/viz.js@2.1.2/full.render.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
        <style>
          body { margin: 0; padding: 0; }
          #graph { width: 100vw; height: 100vh; display: flex; justify-content: center; align-items: center; }
        </style>
      </head>
      <body>
        <div id="graph"></div>
        <script>
          const dot = \`$graph\`;
          const viz = new Viz();
          viz.renderSVGElement(dot)
            .then(function(element) {
              document.getElementById("graph").appendChild(element);
              svgPanZoom(element, {
                zoomEnabled: true,
                controlIconsEnabled: true,
                fit: true,
                center: true,
                minZoom: 0.5,
                maxZoom: 10
              });
            })
            .catch(error => {
              document.getElementById("graph").innerHTML = "<pre>" + error + "</pre>";
            });
        </script>
      </body>
      </html>
    ''';

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: htmlContent,
        baseUrl: WebUri("https://localhost"),
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
    );
  }
}
