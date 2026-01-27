import 'package:flutter/material.dart';

/// A row of filter chips for selecting options.
class FilterChipRow<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onSelected;
  final bool allowClear;

  const FilterChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.allowClear = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (allowClear)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: selected == null,
                      onSelected: (_) => onSelected(null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ...options.map((option) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(labelBuilder(option)),
                        selected: selected == option,
                        onSelected: (_) => onSelected(option),
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of filter chips allowing multiple selections.
class MultiFilterChipRow<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelBuilder;
  final ValueChanged<Set<T>> onChanged;

  const MultiFilterChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labelBuilder(option)),
                    selected: isSelected,
                    onSelected: (_) {
                      final newSet = Set<T>.from(selected);
                      if (isSelected) {
                        newSet.remove(option);
                      } else {
                        newSet.add(option);
                      }
                      onChanged(newSet);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
