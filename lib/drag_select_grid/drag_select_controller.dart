import 'package:flutter/foundation.dart';
import 'grid_section.dart';

/// A Controller that manages multi-selection state, selection modes,
/// and dynamic column configurations for [DynamicDragSelectGrid].
class DragSelectController<T> extends ChangeNotifier {
  final Set<String> _selectedKeys = {};
  final Map<String, T> _selectedItems = {};
  int _crossAxisCount;

  DragSelectController({int initialCrossAxisCount = 3})
    : _crossAxisCount = initialCrossAxisCount;

  /// Current selected keys
  Set<String> get selectedKeys => Set.unmodifiable(_selectedKeys);

  /// Map of selected items keyed by ID
  Map<String, T> get selectedItems => Map.unmodifiable(_selectedItems);

  /// Total number of selected items
  int get selectedCount => _selectedKeys.length;

  /// Whether the grid is currently in selection mode
  bool get isSelectionMode => _selectedKeys.isNotEmpty;

  /// Dynamic column count for the grid view
  int get crossAxisCount => _crossAxisCount;

  /// Update the dynamic column count (e.g., 2, 3, 4, 5 columns)
  set crossAxisCount(int count) {
    if (_crossAxisCount != count && count > 0) {
      _crossAxisCount = count;
      notifyListeners();
    }
  }

  /// Check if a specific item key is selected
  bool isSelected(String key) => _selectedKeys.contains(key);

  /// Toggle selection for an individual item
  void toggle(String key, T item) {
    if (_selectedKeys.contains(key)) {
      _selectedKeys.remove(key);
      _selectedItems.remove(key);
    } else {
      _selectedKeys.add(key);
      _selectedItems[key] = item;
    }
    notifyListeners();
  }

  /// Explicitly select an item
  void select(String key, T item) {
    if (!_selectedKeys.contains(key)) {
      _selectedKeys.add(key);
      _selectedItems[key] = item;
      notifyListeners();
    }
  }

  /// Explicitly deselect an item
  void deselect(String key) {
    if (_selectedKeys.contains(key)) {
      _selectedKeys.remove(key);
      _selectedItems.remove(key);
      notifyListeners();
    }
  }

  /// Batch update selection for a range of items during drag-select
  void updateRange(
    Set<String> initialKeys,
    Map<String, T> initialItems,
    List<T> rangeItems,
    String Function(T) idGetter,
  ) {
    _selectedKeys
      ..clear()
      ..addAll(initialKeys);

    _selectedItems
      ..clear()
      ..addAll(initialItems);

    for (final item in rangeItems) {
      final id = idGetter(item);
      _selectedKeys.add(id);
      _selectedItems[id] = item;
    }

    notifyListeners();
  }

  /// Returns whether a sub-grid section is completely, partially, or not selected
  SectionSelectionState getSectionState(
    List<T> items,
    String Function(T) idGetter,
  ) {
    if (items.isEmpty) return SectionSelectionState.none;
    int selectedInCount = 0;
    for (final item in items) {
      if (_selectedKeys.contains(idGetter(item))) {
        selectedInCount++;
      }
    }

    if (selectedInCount == 0) return SectionSelectionState.none;
    if (selectedInCount == items.length) return SectionSelectionState.all;
    return SectionSelectionState.partial;
  }

  /// Toggle selection for an entire sub-grid section
  void toggleSection(List<T> items, String Function(T) idGetter) {
    final state = getSectionState(items, idGetter);
    if (state == SectionSelectionState.all) {
      // Deselect all in this section
      for (final item in items) {
        final id = idGetter(item);
        _selectedKeys.remove(id);
        _selectedItems.remove(id);
      }
    } else {
      // Select all in this section
      for (final item in items) {
        final id = idGetter(item);
        _selectedKeys.add(id);
        _selectedItems[id] = item;
      }
    }
    notifyListeners();
  }

  /// Select all items across all sections
  void selectAll(List<T> allItems, String Function(T) idGetter) {
    for (final item in allItems) {
      final id = idGetter(item);
      _selectedKeys.add(id);
      _selectedItems[id] = item;
    }
    notifyListeners();
  }

  /// Clear all selected items and exit selection mode
  void clear() {
    if (_selectedKeys.isNotEmpty) {
      _selectedKeys.clear();
      _selectedItems.clear();
      notifyListeners();
    }
  }
}
