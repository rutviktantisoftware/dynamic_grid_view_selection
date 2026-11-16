import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'drag_select_controller.dart';
import 'grid_section.dart';

typedef HeaderWidgetBuilder<H> =
    Widget Function(
      BuildContext context,
      H header,
      SectionSelectionState state,
      VoidCallback onToggleSection,
    );

typedef ItemWidgetBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      bool isSelected,
      bool isSelectionMode,
    );

/// A reusable, high-performance, dynamic sub-grid view featuring:
/// - Generic types [H] (header data) and [T] (item data)
/// - Viewport anchor preservation (keeps current visible images pinned in place when column count changes)
/// - Exact [Rect.lerp] animated layout transition between column counts
/// - Multi-touch Pinch-to-Zoom (drag apart/together to increase/decrease grid item size)
/// - Drag-and-select with automatic viewport edge scrolling
/// - Sub-grid section grouping with tri-state selection headers
/// - Controller-driven dynamic column resizing with smooth animation
class DynamicDragSelectGrid<H, T> extends StatefulWidget {
  final DragSelectController<T> controller;
  final List<GridSection<H, T>> sections;
  final String Function(T item) itemId;
  final HeaderWidgetBuilder<H>? headerBuilder;
  final ItemWidgetBuilder<T> itemBuilder;
  final void Function(T item)? onItemTap;
  final ScrollController? scrollController;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final double autoScrollThreshold;
  final double autoScrollSpeed;
  final double cacheExtent;
  final int minColumns;
  final int maxColumns;
  final bool enablePinchZoom;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget? leading;

  const DynamicDragSelectGrid({
    super.key,
    required this.controller,
    required this.sections,
    required this.itemId,
    this.headerBuilder,
    required this.itemBuilder,
    this.onItemTap,
    this.scrollController,
    this.mainAxisSpacing = 2.0,
    this.crossAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 2.0),
    this.autoScrollThreshold = 100.0,
    this.autoScrollSpeed = 20.0,
    this.cacheExtent = 200.0,
    this.minColumns = 1,
    this.maxColumns = 5,
    this.enablePinchZoom = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOutCubic,
    this.leading,
  });

  @override
  State<DynamicDragSelectGrid<H, T>> createState() =>
      _DynamicDragSelectGridState<H, T>();
}

class _DynamicDragSelectGridState<H, T>
    extends State<DynamicDragSelectGrid<H, T>>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _createdInternalScrollController = false;

  final Map<String, GlobalKey> _itemKeys = {};
  final Map<int, GlobalKey> _headerKeys = {};
  final List<String> _orderedIds = [];
  final Map<String, T> _itemMap = {};

  // Drag-to-select tracking
  String? _dragStartId;
  Set<String> _initialKeys = {};
  Map<String, T> _initialItems = {};
  Timer? _autoScrollTimer;
  Offset _currentPointer = Offset.zero;

  // Multi-touch Pinch tracking
  final Map<int, Offset> _activePointers = {};
  double? _initialPinchDistance;
  Offset _pinchFocalPoint = Offset.zero;

  // Animated column transition state
  late int _currentColumns;
  int _fromColumns = 3;
  int _toColumns = 3;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Floating zoom indicator badge
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;

  // Scroll monitoring to prevent accidental drag-selection while scrolling
  bool _isScrolling = false;
  DateTime _lastScrollTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _createdInternalScrollController = true;
    }

    _currentColumns = widget.controller.crossAxisCount;
    _fromColumns = _currentColumns;
    _toColumns = _currentColumns;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );

    _reindexItems();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant DynamicDragSelectGrid<H, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.sections != widget.sections) {
      _reindexItems();
    }
  }

  void _onControllerChanged() {
    if (widget.controller.crossAxisCount != _currentColumns && !_isAnimating) {
      _animateToColumns(widget.controller.crossAxisCount);
    } else {
      if (mounted) setState(() {});
    }
  }

  void _reindexItems() {
    _orderedIds.clear();
    _itemMap.clear();

    for (final section in widget.sections) {
      for (final item in section.items) {
        final id = widget.itemId(item);
        _itemKeys.putIfAbsent(id, () => GlobalKey());
        _orderedIds.add(id);
        _itemMap[id] = item;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _autoScrollTimer?.cancel();
    _zoomIndicatorTimer?.cancel();
    _animationController.dispose();
    if (_createdInternalScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------
  // VIEWPORT ANCHOR CALCULATIONS
  // -------------------------------------------------------------
  double _getHeaderHeight(int sectionIndex) {
    if (widget.headerBuilder == null) return 0.0;
    final key = _headerKeys[sectionIndex];
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      return renderBox.size.height;
    }
    return 52.0;
  }

  double _calculateSectionHeight(
    int itemCount,
    int columns,
    double contentWidth,
  ) {
    if (itemCount == 0) return 0.0;
    final totalSpacing = widget.crossAxisSpacing * (columns - 1);
    final itemWidth = (contentWidth - totalSpacing) / columns;
    final itemHeight = itemWidth / widget.childAspectRatio;
    final rows = (itemCount / columns).ceil();
    return rows * itemHeight + (rows - 1) * widget.mainAxisSpacing;
  }

  double _calculateTotalScrollExtent(int columns, double contentWidth) {
    double total = 0.0;
    for (int s = 0; s < widget.sections.length; s++) {
      total += _getHeaderHeight(s);
      total += _calculateSectionHeight(
        widget.sections[s].items.length,
        columns,
        contentWidth,
      );
    }
    return total;
  }

  double _calculateItemScrollY(
    String targetId,
    int columns,
    double contentWidth,
  ) {
    double currentY = 0.0;

    for (int s = 0; s < widget.sections.length; s++) {
      final section = widget.sections[s];
      currentY += _getHeaderHeight(s);

      final itemIndex = section.items.indexWhere(
        (item) => widget.itemId(item) == targetId,
      );
      if (itemIndex != -1) {
        final totalSpacing = widget.crossAxisSpacing * (columns - 1);
        final itemWidth = (contentWidth - totalSpacing) / columns;
        final itemHeight = itemWidth / widget.childAspectRatio;

        final row = itemIndex ~/ columns;
        currentY += row * (itemHeight + widget.mainAxisSpacing);
        return currentY;
      } else {
        currentY += _calculateSectionHeight(
          section.items.length,
          columns,
          contentWidth,
        );
      }
    }

    return currentY;
  }

  String? _findAnchorItem(double targetScreenY) {
    String? bestId;
    double minDistance = double.infinity;

    for (final id in _orderedIds) {
      final key = _itemKeys[id];
      if (key == null) continue;
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.attached) {
        final itemTopLeft = renderBox.localToGlobal(Offset.zero);
        final itemCenterY = itemTopLeft.dy + renderBox.size.height / 2;
        final distance = (itemCenterY - targetScreenY).abs();
        if (distance < minDistance) {
          minDistance = distance;
          bestId = id;
        }
      }
    }

    return bestId;
  }

  // -------------------------------------------------------------
  // ANIMATED COLUMN RESIZING WITH ANCHOR PRESERVATION
  // -------------------------------------------------------------
  void _triggerZoomIndicator() {
    _zoomIndicatorTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showZoomIndicator = true;
    });
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showZoomIndicator = false;
        });
      }
    });
  }

  void _animateToColumns(int newColumns) {
    if (newColumns == _currentColumns || _isAnimating) return;

    _triggerZoomIndicator();

    final viewportSize = MediaQuery.of(context).size;
    final padding = widget.padding.resolve(Directionality.of(context));
    final contentWidth = viewportSize.width - padding.left - padding.right;

    // 1. Identify the focal point screen Y coordinate
    final double targetScreenY = _pinchFocalPoint != Offset.zero
        ? _pinchFocalPoint.dy
        : viewportSize.height / 2;

    // 2. Find the anchor item closest to the user's focal point
    final anchorId = _findAnchorItem(targetScreenY);
    final double initialScrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    double targetScrollOffset = initialScrollOffset;

    if (anchorId != null) {
      final anchorBox =
          _itemKeys[anchorId]?.currentContext?.findRenderObject() as RenderBox?;
      if (anchorBox != null && anchorBox.hasSize && anchorBox.attached) {
        final scrollBox = context.findRenderObject() as RenderBox?;
        final scrollGlobalTop =
            scrollBox != null && scrollBox.hasSize && scrollBox.attached
            ? scrollBox.localToGlobal(Offset.zero).dy
            : 0.0;
        final anchorGlobalTop = anchorBox.localToGlobal(Offset.zero).dy;
        final relativeScreenY = anchorGlobalTop - scrollGlobalTop;

        // Calculate where this anchor item will land in the new column layout
        final newY = _calculateItemScrollY(anchorId, newColumns, contentWidth);
        final maxScrollExtent = _calculateTotalScrollExtent(
          newColumns,
          contentWidth,
        );
        targetScrollOffset = (newY - relativeScreenY).clamp(
          0.0,
          maxScrollExtent,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isAnimating = true;
      _fromColumns = _currentColumns;
      _toColumns = newColumns;
      _currentColumns = newColumns;
      widget.controller.crossAxisCount = newColumns;
    });

    // 3. Smoothly animate scroll offset in tandem with item layout animation
    void scrollSyncListener() {
      if (_scrollController.hasClients) {
        final currentOffset =
            ui.lerpDouble(
              initialScrollOffset,
              targetScrollOffset,
              _animation.value,
            ) ??
            initialScrollOffset;
        _scrollController.jumpTo(currentOffset);
      }
    }

    _animation.addListener(scrollSyncListener);

    _animationController.forward().then((_) {
      _animation.removeListener(scrollSyncListener);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(targetScrollOffset);
      }
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _fromColumns = _toColumns;
          _pinchFocalPoint = Offset.zero;
        });
        _animationController.reset();
      }
    });
  }

  void _handlePinchUpdate() {
    if (!widget.enablePinchZoom || _activePointers.length != 2 || _isAnimating) {
      return;
    }

    final points = _activePointers.values.toList();
    final currentDistance = (points[0] - points[1]).distance;
    _pinchFocalPoint = (points[0] + points[1]) / 2;

    if (_initialPinchDistance == null || _initialPinchDistance! <= 0) {
      _initialPinchDistance = currentDistance;
      return;
    }

    final scale = currentDistance / _initialPinchDistance!;

    if (scale > 1.25) {
      // Pinch apart: make items bigger -> decrease columns
      if (_currentColumns > widget.minColumns) {
        _initialPinchDistance = currentDistance;
        _animateToColumns(_currentColumns - 1);
      }
    } else if (scale < 0.80) {
      // Pinch together: make items smaller -> increase columns
      if (_currentColumns < widget.maxColumns) {
        _initialPinchDistance = currentDistance;
        _animateToColumns(_currentColumns + 1);
      }
    }
  }

  // -------------------------------------------------------------
  // AUTO-SCROLL WHEN DRAGGING NEAR VIEWPORT EDGES
  // -------------------------------------------------------------
  void _checkAutoScroll(double pointerGlobalY, double viewportHeight) {
    final edgeThreshold = widget.autoScrollThreshold;
    final maxStep = widget.autoScrollSpeed;

    if (pointerGlobalY < edgeThreshold) {
      final ratio = ((edgeThreshold - pointerGlobalY) / edgeThreshold).clamp(
        0.15,
        1.0,
      );
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          final target = (_scrollController.offset - (maxStep * ratio)).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(target);
          _updateSelectionAtPointer(isScrollingUp: true);
        } else if (_scrollController.hasClients &&
            _scrollController.offset <= 0) {
          _updateSelectionAtPointer(isScrollingUp: true);
        }
      });
    } else if (pointerGlobalY > viewportHeight - edgeThreshold) {
      final ratio =
          ((pointerGlobalY - (viewportHeight - edgeThreshold)) / edgeThreshold)
              .clamp(0.15, 1.0);
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_scrollController.hasClients &&
            _scrollController.offset <
                _scrollController.position.maxScrollExtent) {
          final target = (_scrollController.offset + (maxStep * ratio)).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(target);
          _updateSelectionAtPointer(isScrollingDown: true);
        } else if (_scrollController.hasClients &&
            _scrollController.offset >=
                _scrollController.position.maxScrollExtent) {
          _updateSelectionAtPointer(isScrollingDown: true);
        }
      });
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  // -------------------------------------------------------------
  // ROBUST POINTER HIT-TESTING & TARGET RESOLUTION
  // -------------------------------------------------------------
  String? _findTargetId(
    Offset globalPosition, {
    bool isScrollingDown = false,
    bool isScrollingUp = false,
  }) {
    if (_orderedIds.isEmpty) return null;

    if (_scrollController.hasClients) {
      if (isScrollingDown &&
          _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 5) {
        return _orderedIds.last;
      }
      if (isScrollingUp && _scrollController.offset <= 5) {
        return _orderedIds.first;
      }
    }

    for (final id in _orderedIds) {
      final key = _itemKeys[id];
      if (key == null) continue;

      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.attached) {
        final localPos = renderBox.globalToLocal(globalPosition);
        if (renderBox.paintBounds.contains(localPos)) {
          return id;
        }
      }
    }

    if (isScrollingDown) {
      String? lowestVisibleId;
      int highestIndex = -1;

      for (int i = 0; i < _orderedIds.length; i++) {
        final id = _orderedIds[i];
        final key = _itemKeys[id];
        if (key == null) continue;
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize && renderBox.attached) {
          final itemTopLeft = renderBox.localToGlobal(Offset.zero);
          if (itemTopLeft.dy <= globalPosition.dy + 80) {
            if (i > highestIndex) {
              highestIndex = i;
              lowestVisibleId = id;
            }
          }
        }
      }
      if (lowestVisibleId != null) return lowestVisibleId;
    }

    if (isScrollingUp) {
      String? topVisibleId;
      int lowestIndex = _orderedIds.length;

      for (int i = 0; i < _orderedIds.length; i++) {
        final id = _orderedIds[i];
        final key = _itemKeys[id];
        if (key == null) continue;
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize && renderBox.attached) {
          final itemTopLeft = renderBox.localToGlobal(Offset.zero);
          if (itemTopLeft.dy + renderBox.size.height >=
              globalPosition.dy - 80) {
            if (i < lowestIndex) {
              lowestIndex = i;
              topVisibleId = id;
            }
          }
        }
      }
      if (topVisibleId != null) return topVisibleId;
    }

    String? closestId;
    double minDistance = double.infinity;

    for (final id in _orderedIds) {
      final key = _itemKeys[id];
      if (key == null) continue;
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.attached) {
        final itemCenter = renderBox.localToGlobal(
          Offset(renderBox.size.width / 2, renderBox.size.height / 2),
        );
        final distance = (itemCenter - globalPosition).distance;
        if (distance < minDistance) {
          minDistance = distance;
          closestId = id;
        }
      }
    }

    if (minDistance < 260.0) {
      return closestId;
    }

    return null;
  }

  void _onDragStart(String startId, Offset globalPosition) {
    if (!mounted) return;
    final timeSinceScroll = DateTime.now()
        .difference(_lastScrollTime)
        .inMilliseconds;
    if (_isScrolling ||
        timeSinceScroll < 200 ||
        _activePointers.length >= 2 ||
        _isAnimating) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _dragStartId = startId;
      _currentPointer = globalPosition;
      _initialKeys = Set.from(widget.controller.selectedKeys);
      _initialItems = Map.from(widget.controller.selectedItems);
    });

    final item = _itemMap[startId];
    if (item != null) {
      widget.controller.select(startId, item);
    }
  }

  void _onDragUpdate(Offset globalPosition, double viewportHeight) {
    if (!mounted) return;
    _currentPointer = globalPosition;
    _checkAutoScroll(globalPosition.dy, viewportHeight);
    _updateSelectionAtPointer();
  }

  void _updateSelectionAtPointer({
    bool isScrollingDown = false,
    bool isScrollingUp = false,
  }) {
    if (!mounted || _dragStartId == null) return;

    final targetId = _findTargetId(
      _currentPointer,
      isScrollingDown: isScrollingDown,
      isScrollingUp: isScrollingUp,
    );
    if (targetId == null) return;

    final startIndex = _orderedIds.indexOf(_dragStartId!);
    final targetIndex = _orderedIds.indexOf(targetId);
    if (startIndex == -1 || targetIndex == -1) return;

    final minIndex = startIndex < targetIndex ? startIndex : targetIndex;
    final maxIndex = startIndex < targetIndex ? targetIndex : startIndex;

    final rangeItems = <T>[];
    for (int i = minIndex; i <= maxIndex; i++) {
      final id = _orderedIds[i];
      final item = _itemMap[id];
      if (item != null) rangeItems.add(item);
    }

    final previousCount = widget.controller.selectedCount;
    widget.controller.updateRange(
      _initialKeys,
      _initialItems,
      rangeItems,
      widget.itemId,
    );
    if (widget.controller.selectedCount != previousCount) {
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd() {
    _autoScrollTimer?.cancel();
    if (!mounted) return;
    if (_dragStartId != null) {
      setState(() {
        _dragStartId = null;
      });
    }
  }

  List<Widget> _buildSectionSlivers(int s, GridSection<H, T> section) {
    return [
      if (widget.headerBuilder != null)
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: _headerKeys.putIfAbsent(s, () => GlobalKey()),
            child: widget.headerBuilder!(
              context,
              section.header,
              widget.controller.getSectionState(section.items, widget.itemId),
              () =>
                  widget.controller.toggleSection(section.items, widget.itemId),
            ),
          ),
        ),
      if (_isAnimating)
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return _CustomAnimatedSectionGrid<T>(
              animation: _animation,
              fromColumns: _fromColumns,
              toColumns: _toColumns,
              items: section.items,
              itemId: widget.itemId,
              itemBuilder: widget.itemBuilder,
              isSelected: widget.controller.isSelected,
              isSelectionMode: widget.controller.isSelectionMode,
              onToggle: widget.controller.toggle,
              onItemTap: widget.onItemTap,
              childAspectRatio: widget.childAspectRatio,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              padding: widget.padding is EdgeInsets
                  ? widget.padding as EdgeInsets
                  : EdgeInsets.zero,
            );
          },
        )
      else
        SliverPadding(
          padding: widget.padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _currentColumns,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = section.items[index];
                final id = widget.itemId(item);
                final isSelected = widget.controller.isSelected(id);

                return KeyedSubtree(
                  key: _itemKeys[id],
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.controller.isSelectionMode) {
                        widget.controller.toggle(id, item);
                      } else {
                        widget.onItemTap?.call(item);
                      }
                    },
                    onLongPressStart: (details) {
                      _onDragStart(id, details.globalPosition);
                    },
                    child: widget.itemBuilder(
                      context,
                      item,
                      isSelected,
                      widget.controller.isSelectionMode,
                    ),
                  ),
                );
              },
              childCount: section.items.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Listener(
          onPointerDown: (event) {
            _activePointers[event.pointer] = event.position;
            if (_activePointers.length == 2) {
              final points = _activePointers.values.toList();
              _initialPinchDistance = (points[0] - points[1]).distance;
              _pinchFocalPoint = (points[0] + points[1]) / 2;
              if (_dragStartId != null) {
                _onDragEnd();
              }
            }
          },
          onPointerMove: (event) {
            if (_activePointers.containsKey(event.pointer)) {
              _activePointers[event.pointer] = event.position;
            }

            if (_activePointers.length >= 2) {
              _handlePinchUpdate();
            } else if (_dragStartId != null) {
              _onDragUpdate(event.position, viewportHeight);
            }
          },
          onPointerUp: (event) {
            _activePointers.remove(event.pointer);
            if (_activePointers.length < 2) {
              _initialPinchDistance = null;
            }
            if (_dragStartId != null && _activePointers.isEmpty) {
              _onDragEnd();
            }
          },
          onPointerCancel: (event) {
            _activePointers.remove(event.pointer);
            if (_activePointers.length < 2) {
              _initialPinchDistance = null;
            }
            if (_dragStartId != null && _activePointers.isEmpty) {
              _onDragEnd();
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isScrolling = true;
                _lastScrollTime = DateTime.now();
              } else if (notification is ScrollUpdateNotification) {
                _isScrolling = true;
                _lastScrollTime = DateTime.now();
              } else if (notification is ScrollEndNotification) {
                _isScrolling = false;
                _lastScrollTime = DateTime.now();
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              cacheExtent: widget.cacheExtent,
              physics: (_dragStartId != null || _isAnimating)
                  ? const NeverScrollableScrollPhysics() // lock native scroll while drag-selecting or animating
                  : const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
              slivers: [
                if (widget.leading != null) widget.leading!,
                for (int s = 0; s < widget.sections.length; s++)
                  ..._buildSectionSlivers(s, widget.sections[s]),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),

        // Floating Column Zoom Indicator Pill
        if (_showZoomIndicator)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_view, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$_currentColumns Columns',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated Section Grid applying the exact Rect.lerp position and size interpolation
/// from GestureGridView to animate items smoothly between fromColumns and toColumns.
class _CustomAnimatedSectionGrid<T> extends StatelessWidget {
  final Animation<double> animation;
  final int fromColumns;
  final int toColumns;
  final List<T> items;
  final String Function(T item) itemId;
  final ItemWidgetBuilder<T> itemBuilder;
  final bool Function(String id) isSelected;
  final bool isSelectionMode;
  final void Function(String id, T item) onToggle;
  final void Function(T item)? onItemTap;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;

  const _CustomAnimatedSectionGrid({
    required this.animation,
    required this.fromColumns,
    required this.toColumns,
    required this.items,
    required this.itemId,
    required this.itemBuilder,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggle,
    required this.onItemTap,
    required this.childAspectRatio,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;
            final fromHeight = _calculateTotalHeight(
              items.length,
              fromColumns,
              contentWidth,
            );
            final toHeight = _calculateTotalHeight(
              items.length,
              toColumns,
              contentWidth,
            );
            final currentHeight =
                ui.lerpDouble(fromHeight, toHeight, animation.value) ??
                fromHeight;

            return SizedBox(
              height: currentHeight,
              width: contentWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final id = itemId(item);

                  final fromPos = _calculateItemPosition(
                    index,
                    fromColumns,
                    contentWidth,
                  );
                  final toPos = _calculateItemPosition(
                    index,
                    toColumns,
                    contentWidth,
                  );
                  final currentPos = Rect.lerp(
                    fromPos,
                    toPos,
                    animation.value,
                  )!;

                  return Positioned(
                    left: currentPos.left,
                    top: currentPos.top,
                    width: currentPos.width,
                    height: currentPos.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isSelectionMode) {
                          onToggle(id, item);
                        } else {
                          onItemTap?.call(item);
                        }
                      },
                      child: itemBuilder(
                        context,
                        item,
                        isSelected(id),
                        isSelectionMode,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  Rect _calculateItemPosition(int index, int columns, double contentWidth) {
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final itemWidth = (contentWidth - totalSpacing) / columns;
    final itemHeight = itemWidth / childAspectRatio;

    final row = index ~/ columns;
    final col = index % columns;

    final x = col * (itemWidth + crossAxisSpacing);
    final y = row * (itemHeight + mainAxisSpacing);

    return Rect.fromLTWH(x, y, itemWidth, itemHeight);
  }

  double _calculateTotalHeight(
    int itemCount,
    int columns,
    double contentWidth,
  ) {
    if (itemCount == 0) return 0.0;
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final itemWidth = (contentWidth - totalSpacing) / columns;
    final itemHeight = itemWidth / childAspectRatio;
    final rows = (itemCount / columns).ceil();
    return rows * itemHeight + (rows - 1) * mainAxisSpacing;
  }
}
