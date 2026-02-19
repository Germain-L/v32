---
name: flutter-performance
description: Performance optimization patterns for smooth 60fps Flutter apps
license: MIT
compatibility: opencode
metadata:
  category: performance
  framework: flutter
---

## What I Do

Provide performance optimization patterns for Flutter apps to ensure smooth 60fps UI and efficient resource usage.

## When to Use Me

Use this skill when:
- Optimizing image handling and storage
- Implementing lazy loading for lists
- Reducing widget rebuilds
- Optimizing database queries
- Improving app startup time

## Performance Patterns

### 1. Image Optimization

```dart
// lib/utils/image_compression.dart
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageOptimizer {
  static Future<File> compressImage(
    File source, {
    int maxWidth = 1080,
    int quality = 85,
  }) async {
    final bytes = await source.readAsBytes();
    final original = img.decodeImage(bytes);
    
    if (original == null) return source;
    
    // Resize if too large
    img.Image resized = original;
    if (original.width > maxWidth) {
      resized = img.copyResize(
        original,
        width: maxWidth,
        interpolation: img.Interpolation.linear,
      );
    }
    
    // Compress
    final compressed = img.encodeJpg(resized, quality: quality);
    
    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressed);
    
    return tempFile;
  }
  
  // Usage before saving meal
  static Future<String> saveOptimizedImage(
    File source,
    String targetPath,
  ) async {
    final optimized = await compressImage(source);
    final targetFile = File(targetPath);
    await optimized.copy(targetFile.path);
    await optimized.delete(); // Clean up temp
    return targetFile.path;
  }
}
```

### 2. ListView Optimization

```dart
// lib/presentation/widgets/meal_list.dart
class MealList extends StatelessWidget {
  final List<Meal> meals;
  
  const MealList({super.key, required this.meals});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Essential for performance
      itemCount: meals.length,
      
      // Optional: Improves scroll performance
      itemExtent: 120, // Fixed height for each item
      
      // Optional: Keep items in memory
      cacheExtent: 200, // Pixels to render off-screen
      
      // Use const constructors for children
      itemBuilder: (context, index) {
        final meal = meals[index];
        return MealCard(
          key: ValueKey(meal.id), // Stable keys
          meal: meal,
        );
      },
    );
  }
}

// Optimized MealCard with const
class MealCard extends StatelessWidget {
  final Meal meal;
  
  const MealCard({
    super.key,
    required this.meal,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // Use const for static widgets
        leading: meal.hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(meal.imagePath!),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                // Cache the image
                cacheWidth: 160, // 2x for retina
              ),
            )
          : const Icon(Icons.no_photography),
        title: Text(meal.description ?? 'No description'),
        subtitle: Text(_formatDate(meal.date)),
      ),
    );
  }
}
```

### 3. RepaintBoundary for Complex Widgets

```dart
// lib/presentation/widgets/calendar_view.dart
class CalendarGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        return RepaintBoundary(
          // Isolates this widget's repaint
          child: CalendarDayCell(
            day: index,
            meals: getMealsForDay(index),
          ),
        );
      },
    );
  }
}

// Meal photo widget that changes rarely
class MealPhoto extends StatelessWidget {
  final String imagePath;
  
  const MealPhoto({super.key, required this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Hero(
        tag: imagePath,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
```

### 4. Debounced Input Handling

```dart
// lib/presentation/widgets/auto_save_text_field.dart
class AutoSaveTextField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSave;
  final Duration debounceDuration;
  
  const AutoSaveTextField({
    super.key,
    this.initialValue,
    required this.onSave,
    this.debounceDuration = const Duration(seconds: 1),
  });
  
  @override
  State<AutoSaveTextField> createState() => _AutoSaveTextFieldState();
}

class _AutoSaveTextFieldState extends State<AutoSaveTextField> {
  Timer? _debounceTimer;
  final _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSave(value);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: const InputDecoration(
        hintText: 'Add description...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}
```

### 5. Lazy Loading Images

```dart
// lib/presentation/widgets/lazy_image.dart
class LazyMealImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  
  const LazyMealImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Only decode to this size
      cacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
      cacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
      // Show placeholder while loading
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      // Show error placeholder
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      },
    );
  }
}
```

### 6. Const Constructors

```dart
// lib/presentation/widgets/optimized_widgets.dart

// Always use const where possible
class MealSlot extends StatelessWidget {
  final MealSlotType type;
  final VoidCallback onTap;
  
  const MealSlot({
    super.key,
    required this.type,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // All these are const - won't rebuild
            Icon(Icons.breakfast_dining, size: 48),
            SizedBox(height: 8),
            Text('Breakfast'),
          ],
        ),
      ),
    );
  }
}

// Extract static widgets
class TodayScreen extends StatelessWidget {
  // Static widgets defined once
  static const _slots = [
    _MealSlotConfig(MealSlotType.breakfast, Icons.breakfast_dining),
    _MealSlotConfig(MealSlotType.lunch, Icons.lunch_dining),
    _MealSlotConfig(MealSlotType.afternoonSnack, Icons.cookie),
    _MealSlotConfig(MealSlotType.dinner, Icons.dinner_dining),
  ];
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _slots.map((config) {
        return MealSlot(
          type: config.type,
          icon: config.icon,
        );
      }).toList(),
    );
  }
}

class _MealSlotConfig {
  final MealSlotType type;
  final IconData icon;
  
  const _MealSlotConfig(this.type, this.icon);
}
```

## Best Practices

- Use const constructors for static widgets
- Implement itemExtent in ListView.builder for fixed-size items
- Use RepaintBoundary for complex widgets that change rarely
- Debounce text input to reduce save operations
- Resize and compress images before storage
- Use cacheWidth/cacheHeight to limit image decoding
- Avoid rebuilding entire screens - use granular rebuilds
- Profile with Flutter DevTools to find bottlenecks
- Use ValueKey for stable list item identification
- Cache database query results when appropriate