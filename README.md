# Dynamic Drag Select Grid View for Flutter

A high-performance, dynamic photo-gallery style sub-grid view for Flutter with **Drag-to-Select**, **Multi-Touch Pinch-to-Zoom**, **Sub-Grid Section Grouping**, and **Animated Column Resizing**.

---

## 📱 Demo

<p align="center">
  <video src="Screen_recording_20261116_101438.mp4" controls="controls" autoplay="autoplay" loop="loop" muted="muted" width="360" style="max-width: 100%; border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.2);">
    Your browser does not support the video tag.
  </video>
</p>

> 📹 **Video Demo**: https://github.com/user-attachments/assets/ed70115a-3c3d-49d9-8c52-979fc3be53e4
---

## ✨ Features

- 👆 **Drag-to-Select**: Long-press any item to start selection, then drag across items to seamlessly multi-select or adjust ranges.
- 🤏 **Multi-Touch Pinch-to-Zoom**: Pinch apart or together with two fingers to dynamically increase or decrease grid item size (1 to 5 columns).
- 📍 **Viewport Anchor Preservation**: Keeps the current focal item pinned in view during dynamic column resizing without jumpy scroll resets.
- 🎛️ **Exact `Rect.lerp` Layout Animation**: Smooth visual transition interpolating item positions and sizes when changing column counts.
- 📜 **Edge-Detection Auto-Scroll**: Dragging items near the top or bottom edge of the viewport triggers proportional auto-scrolling.
- 🗂️ **Sub-Grid Section Grouping**: Group items under generic section headers with tri-state checkboxes (`none`, `partial`, `all`) to select or deselect whole sections in a single tap.
- 📳 **Haptic Feedback**: Subtle tactile haptics on selection start and range updates.
- 🎯 **Generic Data Model**: Flexible `DynamicDragSelectGrid<H, T>` where headers (`H`) and items (`T`) can be any model type.

---

## 📂 Project Structure

```
lib/
├── drag_select_grid/
│   ├── drag_select_grid.dart          # Barrel export file
│   ├── dynamic_drag_select_grid.dart  # Main widget with gestures & animations
│   ├── drag_select_controller.dart    # Controller managing selection & columns
│   └── grid_section.dart              # Generic section model & selection state
└── main.dart                          # Complete interactive gallery demo
```

---

## 🚀 Getting Started

### 1. Prerequisites

Ensure you have Flutter installed:
```bash
flutter --version
```

### 2. Run the Demo

Clone the repository and run:
```bash
flutter pub get
flutter run
```

---

## 🛠️ Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:dynamic_grid_view_selection/drag_select_grid/drag_select_grid.dart';

class MyGalleryPage extends StatefulWidget {
  const MyGalleryPage({super.key});

  @override
  State<MyGalleryPage> createState() => _MyGalleryPageState();
}

class _MyGalleryPageState extends State<MyGalleryPage> {
  late final DragSelectController<MyItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = DragSelectController<MyItem>(initialCrossAxisCount: 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Text(
            _controller.isSelectionMode
                ? '${_controller.selectedCount} selected'
                : 'Gallery',
          ),
        ),
      ),
      body: DynamicDragSelectGrid<String, MyItem>(
        controller: _controller,
        sections: [
          GridSection(
            header: 'Recent Photos',
            items: myItemsList,
          ),
        ],
        itemId: (item) => item.id,
        minColumns: 1,
        maxColumns: 5,
        headerBuilder: (context, header, state, onToggle) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
              Checkbox(
                value: state.asTristateBool,
                tristate: true,
                onChanged: (_) => onToggle(),
              ),
            ],
          );
        },
        itemBuilder: (context, item, isSelected, isSelectionMode) {
          return Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
            ),
            child: Image.network(item.url, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
```

---

## 🎮 Gestures & Interactions

| Gesture | Action |
| --- | --- |
| **Long-Press & Drag** | Initiates drag-to-select across multiple grid items. |
| **Pinch Apart** | Increases item size (decreases column count: e.g. 3 → 2). |
| **Pinch Together** | Decreases item size (increases column count: e.g. 3 → 4). |
| **Tap Section Checkbox** | Toggles selection for the entire sub-grid section. |
| **Tap in Selection Mode** | Toggles individual item selection. |
| **Tap in Normal Mode** | Opens item details bottom sheet. |

---

## 📄 License

This project is licensed under the MIT License.
