import 'package:flutter/material.dart';

import '../models/ecs_entity_data.dart';
import 'ecs_event_provider.dart';

final class ECSEntityBrowser extends StatefulWidget {
  const ECSEntityBrowser({super.key});

  @override
  State<ECSEntityBrowser> createState() => _ECSEntityBrowserState();
}

final class _ECSEntityBrowserState extends State<ECSEntityBrowser> {
  String? search;
  String? type;
  String? feature;
  List<ECSEntityData>? data;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refresh();
    });
    super.initState();
  }

  void refresh() async {
    final provider = ECSEventProvider.of(context);
    await provider.waitForServiceInit();
    final data = await provider.requestManagerData();
    update(data.entities);
  }

  void update(List<ECSEntityData> data) {
    setState(() {
      this.data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entities = data ?? <ECSEntityData>[];
    final features = data?.map((e) => e.feature).toSet() ?? <String>{};

    final filtered = entities.where((entity) {
      if (feature != null) {
        if (entity.feature.runtimeType.toString() != feature!) {
          return false;
        }
      }

      if (type != null) {
        if (entity.type != type) {
          return false;
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
                        decoration: const InputDecoration(labelText: 'Feature', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Any')),
                          DropdownMenuItem(value: 'Component', child: Text('Component')),
                          DropdownMenuItem(value: 'Event', child: Text('Event')),
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
                  return const Center(child: Text('No entities found'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                  itemBuilder: (context, index) {
                    final entity = filtered.elementAt(index);

                    if (entity.isEvent) {
                      return ListTile(
                        title: Text('${entity.feature}.${entity.name}'),
                      );
                    }

                    if (entity.isComponent) {
                      return ListTile(
                        title: Text('${entity.feature}.${entity.name}'),
                        subtitle: Text('Value: ${entity.value ?? '--'}'),
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
