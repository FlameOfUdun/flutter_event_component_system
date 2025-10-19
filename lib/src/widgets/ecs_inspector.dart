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
  String? search;
  String? type;
  String? feature;

  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final entities = manager.entities;
    final features = manager.features;

    final filtered = entities.where((entity) {
      if (feature != null) {
        if (entity.feature.runtimeType.toString() != feature!) {
          return false;
        }
      }

      if (type != null) {
        if (type == 'event') {
          if (entity is! ECSEvent) {
            return false;
          }
        }
        if (type == 'component') {
          if (entity is! ECSComponent) {
            return false;
          }
        }
      }

      if (search != null && search!.isNotEmpty) {
        final searchTerm = search!.toLowerCase();
        final entityName = entity.toString().toLowerCase();
        if (!entityName.contains(searchTerm)) {
          return false;
        }
      }

      return true;
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade200,
              title: const Text("Filters"),
              childrenPadding: const EdgeInsets.all(8.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: feature,
                        decoration: const InputDecoration(
                          labelText: 'Feature',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
                          ),
                          DropdownMenuItem(
                            value: 'component',
                            child: Text('Component'),
                          ),
                          DropdownMenuItem(
                            value: 'event',
                            child: Text('Event'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            type = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    labelText: 'Search',
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          search = null;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text(
                    'No entities found',
                  ));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                  itemBuilder: (context, index) {
                    final entity = filtered.elementAt(index);

                    if (entity is ECSEvent) {
                      return ExpansionTile(
                        title: Text('${entity.feature.runtimeType}.${entity.runtimeType}'),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [entity.buildInspector(context)],
                      );
                    }

                    if (entity is ECSComponent) {
                      return ExpansionTile(
                        title: Text('${entity.feature.runtimeType}.${entity.runtimeType}'),
                        childrenPadding: const EdgeInsets.all(8),
                        expandedAlignment: Alignment.centerLeft,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [entity.buildInspector(context, entity.value)],
                      );
                    }

                    throw UnimplementedError('Unknown entity type: ${entity.runtimeType}');
                  },
                );
              },
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
  String? search;
  ECSLogLevel? level;

  @override
  Widget build(BuildContext context) {
    final entries = ECSLogger.entries.reversed;

    final filtered = entries.where((entry) {
      if (level != null) {
        if (entry.level != level) {
          return false;
        }
      }

      if (search != null) {
        final searchTerm = search!.toLowerCase();
        final description = entry.description.toLowerCase();
        if (!description.contains(searchTerm)) {
          return false;
        }
      }

      return true;
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade200,
              title: const Text("Logs Info"),
              childrenPadding: const EdgeInsets.all(8.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: level,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          minimumSize: const Size.fromHeight(55),
                        ),
                        onPressed: () {
                          setState(() {
                            ECSLogger.clear();
                          });
                        },
                        child: const Text('Clear Logs'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    labelText: 'Search',
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          search = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
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
                        const Row(children: [
                          Text('Call Stack:'),
                        ]),
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

  var excludeFeatures = <Type>{};

  void analyse(ECSManager manager) {
    final analysis = ECSAnalyzer.analize(
      manager,
      excludeFeatures: excludeFeatures,
    );
    final graph = analysis.generateDotGraph();
    controller!.evaluateJavascript(
      source: '''window.updateGraph(`${graph.replaceAll('`', '\\`')}`);''',
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ECSScope.of(context);
    final features = manager.features;

    return Material(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade200,
              title: const Text("Filters"),
              childrenPadding: const EdgeInsets.all(8.0),
              children: List.generate(features.length, (index) {
                final feature = features.elementAt(index);
                return CheckboxListTile(
                  value: !excludeFeatures.contains(feature.runtimeType),
                  title: Text(feature.runtimeType.toString()),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        excludeFeatures.remove(feature.runtimeType);
                      } else {
                        excludeFeatures.add(feature.runtimeType);
                      }
                      analyse(manager);
                    });
                  },
                );
              }),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialFile: "packages/flutter_event_component_system/assets/ecs_graph.html",
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (webViewController) {
                controller = webViewController;
              },
              onLoadStop: (webViewController, url) {
                controller = webViewController;
                analyse(manager);
              },
            ),
          ),
        ],
      ),
    );
  }
}
