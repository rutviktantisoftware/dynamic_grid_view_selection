enum SectionSelectionState {
  none,
  partial,
  all;

  bool? get asTristateBool {
    switch (this) {
      case SectionSelectionState.all:
        return true;
      case SectionSelectionState.partial:
        return null;
      case SectionSelectionState.none:
        return false;
    }
  }
}

/// Generic container representing a sub-grid section with a header and items of type [T].
class GridSection<H, T> {
  final H header;
  final List<T> items;

  const GridSection({required this.header, required this.items});
}
