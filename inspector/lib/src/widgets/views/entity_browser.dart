import 'package:flutter/material.dart';

import '../../models/inspector_data.dart';
import '../../state/inspector_state.dart';
import '../../theme/inspector_theme.dart';
import '../components/filter_chip_row.dart';
import '../components/search_field.dart';

/// Entity browser view for inspecting components and events.
final class EntityBrowser extends StatelessWidget {
  final InspectorState state;

  const EntityBrowser({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final filter = state.entityFilter;
        final entities = state.filteredEntities;

        return Column(
          children: [
            _buildToolbar(context, filter),
            const Divider(height: 1),
            Expanded(
              child: entities.isEmpty
                  ? _buildEmptyState()
                  : _buildEntityList(entities),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, EntityFilter filter) {
    final features = state.data.featureNames.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search entities...',
            onChanged: (query) {
              state.setEntityFilter(filter.copyWith(searchQuery: query));
            },
          ),
          const SizedBox(height: 12),
          if (features.isNotEmpty)
            FilterChipRow<String>(
              label: 'Feature',
              options: features,
              selected: filter.featureName,
              labelBuilder: (f) => f,
              onSelected: (f) {
                state.setEntityFilter(
                  f == null
                      ? filter.copyWith(clearFeature: true)
                      : filter.copyWith(featureName: f),
                );
              },
            ),
          const SizedBox(height: 8),
          FilterChipRow<EntityType>(
            label: 'Type',
            options: EntityType.values,
            selected: filter.type,
            labelBuilder: (t) => switch (t) {
              EntityType.component => 'Components',
              EntityType.event => 'Events',
              EntityType.dataEvent => 'Data Events',
              EntityType.dependency => 'Dependencies',
            },
            onSelected: (t) {
              state.setEntityFilter(
                t == null
                    ? filter.copyWith(clearType: true)
                    : filter.copyWith(type: t),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: InspectorTheme.mutedText,
          ),
          const SizedBox(height: 16),
          Text(
            'No entities found',
            style: TextStyle(
              color: InspectorTheme.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: InspectorTheme.mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityList(List<EntityData> entities) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entities.length,
      itemBuilder: (context, index) => _EntityCard(entity: entities[index]),
    );
  }
}

final class _EntityCard extends StatelessWidget {
  final EntityData entity;

  const _EntityCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final color = switch (entity.type) {
      EntityType.component => InspectorTheme.componentColor,
      EntityType.event => InspectorTheme.eventColor,
      EntityType.dataEvent => InspectorTheme.eventColor,
      EntityType.dependency => InspectorTheme.secondaryText,
    };

    final icon = switch (entity.type) {
      EntityType.component   => Icons.inventory_2_outlined,
      EntityType.event       => Icons.bolt_outlined,
      EntityType.dataEvent   => Icons.data_object_outlined,
      EntityType.dependency  => Icons.link_outlined,
    };

    final typeLabel = switch (entity.type) {
      EntityType.component => 'Component',
      EntityType.event => 'Event',
      EntityType.dataEvent => 'Data Event',
      EntityType.dependency => 'Dependency',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          entity.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            _TypeBadge(label: typeLabel, color: color),
            const SizedBox(width: 8),
            _TypeBadge(
              label: entity.featureName,
              color: InspectorTheme.secondaryText,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Identifier', value: entity.identifier),
                if (entity.value != null)
                  _DetailRow(label: 'Current Value', value: entity.value!),
                if (entity.previous != null)
                  _DetailRow(label: 'Previous Value', value: entity.previous!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: InspectorTheme.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
