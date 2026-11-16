import 'package:flutter/material.dart';
import 'drag_select_grid/drag_select_grid.dart';

void main() {
  runApp(const DynamicGridDemoApp());
}

/// Sample data model representing a photo or media card in the gallery.
class MediaItem {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final List<Color> gradientColors;
  final IconData icon;
  final String? videoDuration;
  bool isFavorite;

  MediaItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.gradientColors,
    required this.icon,
    this.videoDuration,
    this.isFavorite = false,
  });
}

class DynamicGridDemoApp extends StatelessWidget {
  const DynamicGridDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Drag Select Grid',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      home: const GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final DragSelectController<MediaItem> _controller;
  late final ScrollController _scrollController;
  late List<GridSection<String, MediaItem>> _sections;

  @override
  void initState() {
    super.initState();
    _controller = DragSelectController<MediaItem>(initialCrossAxisCount: 3);
    _scrollController = ScrollController();
    _sections = _generateMockSections();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<GridSection<String, MediaItem>> _generateMockSections() {
    return [
      GridSection(
        header: 'Today • Tokyo, Japan',
        items: [
          MediaItem(
            id: 'tokyo_1',
            title: 'Shibuya Crossing',
            location: 'Shibuya, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFF6366F1), Color(0xFFA855F7)],
            icon: Icons.location_city,
          ),
          MediaItem(
            id: 'tokyo_2',
            title: 'Shinjuku Neon Lights',
            location: 'Shinjuku, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
            icon: Icons.nightlife,
            videoDuration: '0:45',
          ),
          MediaItem(
            id: 'tokyo_3',
            title: 'Senso-ji Temple',
            location: 'Asakusa, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFFEF4444), Color(0xFFF97316)],
            icon: Icons.temple_buddhist,
          ),
          MediaItem(
            id: 'tokyo_4',
            title: 'Ramen Ichiran',
            location: 'Roppongi, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFEAB308)],
            icon: Icons.ramen_dining,
          ),
          MediaItem(
            id: 'tokyo_5',
            title: 'Tokyo Skytree Sunset',
            location: 'Sumida, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
            icon: Icons.camera_alt,
            isFavorite: true,
          ),
          MediaItem(
            id: 'tokyo_6',
            title: 'Akihabara Arcade',
            location: 'Akihabara, Tokyo',
            date: DateTime.now(),
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            icon: Icons.videogame_asset,
          ),
        ],
      ),
      GridSection(
        header: 'Yesterday • Kyoto Gardens',
        items: [
          MediaItem(
            id: 'kyoto_1',
            title: 'Fushimi Inari Torii',
            location: 'Kyoto, Japan',
            date: DateTime.now().subtract(const Duration(days: 1)),
            gradientColors: const [Color(0xFFDC2626), Color(0xFFEA580C)],
            icon: Icons.wb_sunny,
            isFavorite: true,
          ),
          MediaItem(
            id: 'kyoto_2',
            title: 'Bamboo Forest Walk',
            location: 'Arashiyama, Kyoto',
            date: DateTime.now().subtract(const Duration(days: 1)),
            gradientColors: const [Color(0xFF16A34A), Color(0xFF0D9488)],
            icon: Icons.forest,
            videoDuration: '1:12',
          ),
          MediaItem(
            id: 'kyoto_3',
            title: 'Kinkaku-ji Golden Pavilion',
            location: 'Kita, Kyoto',
            date: DateTime.now().subtract(const Duration(days: 1)),
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            icon: Icons.wb_twilight,
          ),
          MediaItem(
            id: 'kyoto_4',
            title: 'Traditional Matcha Tea',
            location: 'Gion, Kyoto',
            date: DateTime.now().subtract(const Duration(days: 1)),
            gradientColors: const [Color(0xFF84CC16), Color(0xFF4D7C0F)],
            icon: Icons.coffee,
          ),
          MediaItem(
            id: 'kyoto_5',
            title: 'Gion Geisha District',
            location: 'Gion, Kyoto',
            date: DateTime.now().subtract(const Duration(days: 1)),
            gradientColors: const [Color(0xFF475569), Color(0xFF1E293B)],
            icon: Icons.architecture,
          ),
        ],
      ),
      GridSection(
        header: 'Last Weekend • Mt. Fuji Adventure',
        items: [
          MediaItem(
            id: 'fuji_1',
            title: 'Lake Kawaguchiko Sunrise',
            location: 'Yamanashi, Japan',
            date: DateTime.now().subtract(const Duration(days: 6)),
            gradientColors: const [Color(0xFF0284C7), Color(0xFF0369A1)],
            icon: Icons.landscape,
            isFavorite: true,
          ),
          MediaItem(
            id: 'fuji_2',
            title: 'Chureito Pagoda View',
            location: 'Fujiyoshida, Japan',
            date: DateTime.now().subtract(const Duration(days: 6)),
            gradientColors: const [Color(0xFFD946EF), Color(0xFF8B5CF6)],
            icon: Icons.photo_camera,
          ),
          MediaItem(
            id: 'fuji_3',
            title: 'Summit Trail Trek',
            location: 'Mount Fuji, Japan',
            date: DateTime.now().subtract(const Duration(days: 6)),
            gradientColors: const [Color(0xFF4B5563), Color(0xFF374151)],
            icon: Icons.hiking,
            videoDuration: '2:30',
          ),
          MediaItem(
            id: 'fuji_4',
            title: 'Hot Spring Onsen',
            location: 'Hakone, Japan',
            date: DateTime.now().subtract(const Duration(days: 7)),
            gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
            icon: Icons.hot_tub,
          ),
          MediaItem(
            id: 'fuji_5',
            title: 'Cedar Forest Cabin',
            location: 'Hakone, Japan',
            date: DateTime.now().subtract(const Duration(days: 7)),
            gradientColors: const [Color(0xFF059669), Color(0xFF065F46)],
            icon: Icons.cottage,
          ),
          MediaItem(
            id: 'fuji_6',
            title: 'Campfire under Stars',
            location: 'Lake Saiko, Japan',
            date: DateTime.now().subtract(const Duration(days: 7)),
            gradientColors: const [Color(0xFF312E81), Color(0xFF1E1B4B)],
            icon: Icons.nights_stay,
          ),
        ],
      ),
      GridSection(
        header: 'October • Hokkaido Fall Foliage',
        items: [
          MediaItem(
            id: 'hokkaido_1',
            title: 'Daisetsuzan Autumn Colors',
            location: 'Hokkaido, Japan',
            date: DateTime.now().subtract(const Duration(days: 20)),
            gradientColors: const [Color(0xFFEA580C), Color(0xFF9A3412)],
            icon: Icons.nature,
          ),
          MediaItem(
            id: 'hokkaido_2',
            title: 'Shirogane Blue Pond',
            location: 'Biei, Hokkaido',
            date: DateTime.now().subtract(const Duration(days: 21)),
            gradientColors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
            icon: Icons.water,
            isFavorite: true,
          ),
          MediaItem(
            id: 'hokkaido_3',
            title: 'Otaru Canal at Dusk',
            location: 'Otaru, Hokkaido',
            date: DateTime.now().subtract(const Duration(days: 22)),
            gradientColors: const [Color(0xFF7C3AED), Color(0xFF4C1D95)],
            icon: Icons.directions_boat,
            videoDuration: '0:55',
          ),
          MediaItem(
            id: 'hokkaido_4',
            title: 'Fresh Seafood Market',
            location: 'Sapporo, Hokkaido',
            date: DateTime.now().subtract(const Duration(days: 23)),
            gradientColors: const [Color(0xFFF97316), Color(0xFFC2410C)],
            icon: Icons.set_meal,
          ),
        ],
      ),
    ];
  }

  List<MediaItem> get _allMediaItems => [
    for (final section in _sections) ...section.items,
  ];

  void _showItemDetails(MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(item.icon, size: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.location,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.videoDuration != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.videocam, size: 16),
                    const SizedBox(width: 4),
                    Text(item.videoDuration!),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          item.isFavorite = !item.isFavorite;
                        });
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        item.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: item.isFavorite ? Colors.red : null,
                      ),
                      label: Text(
                        item.isFavorite ? 'Unfavorite' : 'Favorite',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.select(item.id, item);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Select'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteSelectedItems() {
    final count = _controller.selectedCount;
    if (count == 0) return;

    final selectedKeys = _controller.selectedKeys;
    setState(() {
      _sections = [
        for (final section in _sections)
          GridSection(
            header: section.header,
            items: section.items
                .where((item) => !selectedKeys.contains(item.id))
                .toList(),
          ),
      ].where((s) => s.items.isNotEmpty).toList();
    });

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted $count items'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isSelectionMode = _controller.isSelectionMode;
        final selectedCount = _controller.selectedCount;
        final allItems = _allMediaItems;
        final isAllSelected =
            allItems.isNotEmpty && selectedCount == allItems.length;

        return Scaffold(
          appBar: AppBar(
            elevation: isSelectionMode ? 2 : 0,
            leading: isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Exit selection',
                    onPressed: _controller.clear,
                  )
                : null,
            title: isSelectionMode
                ? Text(
                    '$selectedCount selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : const Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Photos & Gallery',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
            actions: [
              if (isSelectionMode) ...[
                IconButton(
                  icon: Icon(
                    isAllSelected
                        ? Icons.deselect_outlined
                        : Icons.select_all_outlined,
                  ),
                  tooltip: isAllSelected ? 'Deselect all' : 'Select all',
                  onPressed: () {
                    if (isAllSelected) {
                      _controller.clear();
                    } else {
                      _controller.selectAll(allItems, (item) => item.id);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: _deleteSelectedItems,
                ),
              ] else ...[
                // Column count toggle popover/menu
                PopupMenuButton<int>(
                  icon: const Icon(Icons.view_column_outlined),
                  tooltip: 'Columns',
                  initialValue: _controller.crossAxisCount,
                  onSelected: (columns) {
                    _controller.crossAxisCount = columns;
                  },
                  itemBuilder: (context) => [
                    for (int count = 1; count <= 5; count++)
                      PopupMenuItem(
                        value: count,
                        child: Row(
                          children: [
                            Icon(
                              _controller.crossAxisCount == count
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: _controller.crossAxisCount == count
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text('$count Columns'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              // Hint Banner explaining gestures
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSelectionMode
                            ? 'Tap to toggle • Drag across items to multi-select'
                            : 'Pinch to zoom (1-5 cols) • Long-press & drag to select',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // Quick column buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int cols in [2, 3, 4])
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _controller.crossAxisCount = cols,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _controller.crossAxisCount == cols
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${cols}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _controller.crossAxisCount == cols
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // The Dynamic Drag-Select Grid
              Expanded(
                child: DynamicDragSelectGrid<String, MediaItem>(
                  controller: _controller,
                  scrollController: _scrollController,
                  sections: _sections,
                  itemId: (item) => item.id,
                  minColumns: 1,
                  maxColumns: 5,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 3.0,
                  crossAxisSpacing: 3.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3.0,
                    vertical: 2.0,
                  ),
                  onItemTap: _showItemDetails,
                  headerBuilder: (context, header, state, onToggleSection) {
                    return _buildSectionHeader(
                      context,
                      header,
                      state,
                      onToggleSection,
                    );
                  },
                  itemBuilder: (context, item, isSelected, isSelectionMode) {
                    return _buildGridItem(
                      context,
                      item,
                      isSelected,
                      isSelectionMode,
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: isSelectionMode
              ? BottomAppBar(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.favorite_outline),
                        label: const Text('Favorite'),
                        onPressed: selectedCount > 0
                            ? () {
                                final selectedKeys = _controller.selectedKeys;
                                setState(() {
                                  for (final item in _allMediaItems) {
                                    if (selectedKeys.contains(item.id)) {
                                      item.isFavorite = true;
                                    }
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added $selectedCount items to favorites',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: selectedCount > 0
                            ? _deleteSelectedItems
                            : null,
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String header,
    SectionSelectionState state,
    VoidCallback onToggleSection,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              header,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggleSection,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state == SectionSelectionState.all
                        ? 'Deselect'
                        : state == SectionSelectionState.partial
                        ? 'Select all'
                        : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: state != SectionSelectionState.none
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Checkbox(
                    value: state.asTristateBool,
                    tristate: true,
                    onChanged: (_) => onToggleSection(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    MediaItem item,
    bool isSelected,
    bool isSelectionMode,
  ) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSelected ? 14 : 8),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.black.withValues(alpha: 0.08),
          width: isSelected ? 3 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSelected ? 11 : 7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail / Gradient artwork
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),

            // Dimmed overlay when selected
            if (isSelected)
              Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.28),
              ),

            // Item Title badge at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.isFavorite)
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 11,
                      ),
                  ],
                ),
              ),
            ),

            // Video duration badge
            if (item.videoDuration != null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.videoDuration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Selection indicator badge (Top Right)
            if (isSelectionMode || isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.black.withValues(alpha: 0.35),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
