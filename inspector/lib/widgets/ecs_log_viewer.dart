import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_event_component_system_inspector/models/ecs_log_data.dart';
import 'package:flutter_event_component_system_inspector/models/ecs_manager_data.dart';

import 'ecs_event_provider.dart';

final class ECSLogViewer extends StatefulWidget {
  const ECSLogViewer({super.key});

  @override
  State<ECSLogViewer> createState() => _LogsViewState();
}

final class _LogsViewState extends State<ECSLogViewer> {
  String? search;
  String? level;

  ECSManagerData? data;
  DateTime? clearedAt;
  Timer? refreshTimer;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        refresh();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void refresh() async {
    final provider = ECSEventProvider.of(context);
    await provider.waitForServiceInit();
    final data = await provider.requestManagerData();
    update(data);
  }

  void update(ECSManagerData data) {
    setState(() {
      this.data = data;
    });
  }

  List<ECSLogData> get logs {
    var logs = data?.logs ?? [];
    if (clearedAt != null) {
      logs = logs.where((log) => log.time.isAfter(clearedAt!)).toList();
    }

    return logs.where((log) {
      if (level != null) {
        if (log.level != level) {
          return false;
        }
      }
      if (search != null) {
        final term = search!.toLowerCase();
        final message = log.message.toLowerCase();
        if (!message.contains(term)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: DropdownButtonFormField(
                        initialValue: level,
                        decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                        items: ["warning", "error", "debug", "verbose", "fatal"].map((level) {
                          return DropdownMenuItem(value: level, child: Text(level.toUpperCase()));
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                          minimumSize: const Size.fromHeight(55),
                        ),
                        onPressed: () {
                          setState(() {
                            logs.clear();
                            clearedAt = DateTime.now();
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
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (logs.isEmpty) {
                  return const Center(child: Text('No logs found'));
                }
                return ListView.separated(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs.elementAt(index);
                    return ExpansionTile(
                      title: Text('${log.level.toUpperCase()} - ${log.time}'),
                      subtitle: Text(log.message),
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
        ],
      ),
    );
  }
}
