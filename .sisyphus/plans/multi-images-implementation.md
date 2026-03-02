# Multi-Images Per Meal - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Replace single-image-per-meal with unlimited images support using a relational database schema and reorganized file storage.

**Architecture:** Create `meal_images` table with foreign key to meals. Store images in `meal_images/{meal_id}/` directories. Two-build approach: migration build converts existing data, clean build is the ongoing version.

**Tech Stack:** Flutter, sqflite, image_picker (with multi-select), path_provider

---

## Phase 1: Migration Build (One-Time Use)

- [x] **COMPLETED**

**Files:**
- Create: `lib/data/models/meal_image.dart`

**Step 1: Create the model class**

```dart
class MealImage {
  final int? id;
  final int mealId;
  final String imagePath;
  final DateTime createdAt;

  MealImage({
    this.id,
    required this.mealId,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_id': mealId,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MealImage.fromMap(Map<String, dynamic> map) {
    return MealImage(
      id: map['id'] as int?,
      mealId: map['meal_id'] as int,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
```

**Step 2: Verify file structure**

Check that `lib/data/models/` contains `meal.dart`, `day_rating.dart`, etc.

**Step 3: Commit**

```bash
git add lib/data/models/meal_image.dart
git commit -m "feat: add MealImage model for multi-image support"
```

---

- [x] **COMPLETED**

**Files:**
- Create: `lib/data/repositories/meal_image_repository.dart`
- Reference: `lib/data/repositories/meal_repository.dart` (follow same patterns)

**Step 1: Create the repository class**

```dart
import '../models/meal_image.dart';
import '../services/database_service.dart';

class MealImageRepository {
  Future<List<MealImage>> getImagesForMeal(int mealId) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'meal_images',
      where: 'meal_id = ?',
      whereArgs: [mealId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => MealImage.fromMap(m)).toList();
  }

  Future<MealImage> addImage(int mealId, String imagePath) async {
    final db = await DatabaseService.database;
    final now = DateTime.now();
    
    final id = await db.insert('meal_images', {
      'meal_id': mealId,
      'image_path': imagePath,
      'created_at': now.millisecondsSinceEpoch,
    });
    
    await DatabaseService.notifyChange(table: 'meal_images');
    
    return MealImage(
      id: id,
      mealId: mealId,
      imagePath: imagePath,
      createdAt: now,
    );
  }

  Future<void> deleteImage(int imageId) async {
    final db = await DatabaseService.database;
    await db.delete(
      'meal_images',
      where: 'id = ?',
      whereArgs: [imageId],
    );
    await DatabaseService.notifyChange(table: 'meal_images');
  }

  Future<void> deleteAllImagesForMeal(int mealId) async {
    final db = await DatabaseService.database;
    await db.delete(
      'meal_images',
      where: 'meal_id = ?',
      whereArgs: [mealId],
    );
    await DatabaseService.notifyChange(table: 'meal_images');
  }
}
```

**Step 2: Commit**

```bash
git add lib/data/repositories/meal_image_repository.dart
git commit -m "feat: add MealImageRepository for image CRUD operations"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/data/services/database_service.dart:38-148`

**Step 1: Update database version**

Change `version: 4` to `version: 5` on lines 38 and 48.

**Step 2: Add v5 migration in _onUpgrade**

Add at end of `_onUpgrade` method (before closing brace):

```dart
if (oldVersion < 5) {
  // Create meal_images table
  await db.execute('''
    CREATE TABLE meal_images(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      meal_id INTEGER NOT NULL,
      image_path TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_meal_images_meal_id ON meal_images(meal_id)',
  );
  await db.execute(
    'CREATE INDEX idx_meal_images_created_at ON meal_images(created_at)',
  );
}
```

**Step 3: Update _onCreate for new installs**

Add meal_images table creation in `_onCreate` after meals table (around line 62):

```dart
await db.execute('''
  CREATE TABLE meal_images(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER NOT NULL,
    image_path TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
  )
''');
await db.execute(
  'CREATE INDEX idx_meal_images_meal_id ON meal_images(meal_id)',
);
await db.execute(
  'CREATE INDEX idx_meal_images_created_at ON meal_images(created_at)',
);
```

**Step 4: Commit**

```bash
git add lib/data/services/database_service.dart
git commit -m "feat: add meal_images table and v5 migration"
```

---

- [x] **COMPLETED**

**Files:**
- Create: `lib/data/services/image_migration_service.dart`
- Reference: `lib/data/services/image_storage_service.dart`

**Step 1: Create migration service**

```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';

class ImageMigrationService {
  static Future<void> migrateExistingImages() async {
    final db = await DatabaseService.database;
    
    // Get all meals with images
    final mealsWithImages = await db.query(
      'meals',
      where: 'imagePath IS NOT NULL AND imagePath != ""',
    );
    
    print('Migrating ${mealsWithImages.length} meals with images...');
    
    for (final meal in mealsWithImages) {
      final mealId = meal['id'] as int;
      final oldPath = meal['imagePath'] as String;
      
      try {
        final oldFile = File(oldPath);
        if (!await oldFile.exists()) {
          print('Skipping meal $mealId - image not found at $oldPath');
          continue;
        }
        
        // Create meal-specific directory
        final baseDir = await ImageStorageService.getImagesDirectory();
        final mealDir = Directory(path.join(baseDir.path, mealId.toString()));
        await mealDir.create(recursive: true);
        
        // Move image file
        final fileName = path.basename(oldPath);
        final newPath = path.join(mealDir.path, fileName);
        await oldFile.rename(newPath);
        
        // Insert into meal_images
        await db.insert('meal_images', {
          'meal_id': mealId,
          'image_path': newPath,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('Migrated meal $mealId: $fileName');
      } catch (e) {
        print('Error migrating meal $mealId: $e');
      }
    }
    
    print('Migration complete!');
  }
}
```

**Step 2: Update ImageStorageService to expose directory**

Add to `lib/data/services/image_storage_service.dart`:

```dart
static Future<Directory> getImagesDirectory() async {
  return await _directory;
}
```

**Step 3: Commit**

```bash
git add lib/data/services/image_migration_service.dart lib/data/services/image_storage_service.dart
git commit -m "feat: add image migration service to move files to meal_id folders"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/main.dart` or `lib/app.dart`

**Step 1: Add migration call on startup**

In your app initialization (where database is initialized), add:

```dart
import 'data/services/image_migration_service.dart';

// After database initialization
await ImageMigrationService.migrateExistingImages();
```

**Step 2: Commit**

```bash
git add lib/main.dart  # or wherever you add it
git commit -m "feat: trigger image migration on app startup"
```

---

- [x] **COMPLETED**

**Step 1: Build the app**

```bash
flutter build ios  # or android
```

**Step 2: Install on device and run once**

**Step 3: Verify migration**
- Check that images appear in new locations
- Verify database has meal_images rows

**Step 4: Tag this build**

```bash
git tag -a migration-build -m "Build for migrating single images to multi-image schema"
```

---

## Phase 2: Clean Build (Ongoing Version)

- [x] **COMPLETED**

**Files:**
- Modify: `lib/main.dart`
- Keep: `lib/data/services/image_migration_service.dart` (for reference, or delete)

**Step 1: Remove migration trigger**

Remove the `ImageMigrationService.migrateExistingImages()` call from startup.

**Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "chore: remove migration trigger from startup"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/data/models/meal.dart`

**Step 1: Remove imagePath field**

Remove:
- `final String? imagePath;` field
- `imagePath` parameter from constructor
- `'imagePath': imagePath,` from toMap()
- `imagePath: map['imagePath'] as String?,` from fromMap()
- `imagePath` parameter from copyWith()
- `bool get hasImage => imagePath != null && imagePath!.isNotEmpty;`

**Step 2: Commit**

```bash
git add lib/data/models/meal.dart
git commit -m "refactor: remove single imagePath from Meal model"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/data/repositories/meal_repository.dart`
- Modify: `lib/data/repositories/meal_repository_interface.dart`

**Step 1: Remove image handling from repository**

Remove any image path parameters or handling from saveMeal and other methods.

**Step 2: Commit**

```bash
git add lib/data/repositories/meal_repository.dart lib/data/repositories/meal_repository_interface.dart
git commit -m "refactor: remove image handling from meal repository"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/data/services/image_storage_service.dart`

**Step 1: Add method to save image for specific meal**

```dart
static Future<String?> saveImageForMeal(
  File sourceFile,
  int mealId, {
  int maxWidth = 1200,
  int quality = 85,
  int maxBytes = 12 * 1024 * 1024,
}) async {
  try {
    // Create meal-specific directory
    final baseDir = await _directory;
    final mealDir = Directory(path.join(baseDir.path, mealId.toString()));
    await mealDir.create(recursive: true);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBits = timestamp.remainder(1000000);
    final fileName = '${timestamp}_$randomBits.jpg';
    final targetPath = path.join(mealDir.path, fileName);
    
    // ... rest of existing saveImage logic ...
    // (compression, resizing, etc.)
    
    return targetPath;
  } catch (e) {
    return null;
  }
}
```

**Step 2: Commit**

```bash
git add lib/data/services/image_storage_service.dart
git commit -m "feat: add saveImageForMeal with meal_id folder structure"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/presentation/widgets/meal_slot.dart`

**Step 1: Update to use MealImageRepository**

```dart
// Add import
import '../../data/repositories/meal_image_repository.dart';
import '../../data/models/meal_image.dart';

// In widget state
final _imageRepository = MealImageRepository();
List<MealImage> _images = [];

// Load images
Future<void> _loadImages() async {
  if (_meal?.id != null) {
    final images = await _imageRepository.getImagesForMeal(_meal!.id!);
    setState(() => _images = images);
  }
}
```

**Step 2: Update UI to show multiple images**

Replace single image display with horizontal ListView of thumbnails.

**Step 3: Commit**

```bash
git add lib/presentation/widgets/meal_slot.dart
git commit -m "feat: update meal slot widget for multi-image display"
```

---

- [x] **COMPLETED**

**Files:**
- Reference: `lib/presentation/providers/day_detail_provider.dart` (current picker usage)

**Step 1: Update picker to support multi-select**

```dart
import 'package:image_picker/image_picker.dart';

// In your provider or widget
final ImagePicker _picker = ImagePicker();

Future<void> pickMultipleImages(int mealId) async {
  final pickedFiles = await _picker.pickMultiImage(
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  
  for (final pickedFile in pickedFiles) {
    final file = File(pickedFile.path);
    final savedPath = await ImageStorageService.saveImageForMeal(file, mealId);
    if (savedPath != null) {
      await _imageRepository.addImage(mealId, savedPath);
    }
  }
  
  // Notify listeners to refresh UI
  notifyListeners();
}
```

**Step 2: Commit**

```bash
git add lib/presentation/providers/...
git commit -m "feat: add multi-select image picker support"
```

---

- [x] **COMPLETED**

**Files:**
- Create: `lib/presentation/widgets/image_gallery_view.dart`

**Step 1: Create full-screen gallery widget**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/meal_image.dart';

class ImageGalleryView extends StatefulWidget {
  final List<MealImage> images;
  final int initialIndex;
  final Function(int imageId) onDelete;
  
  const ImageGalleryView({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.onDelete,
  });
  
  @override
  State<ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<ImageGalleryView> {
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.images[index].imagePath),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete(widget.images[_currentIndex].id!);
              Navigator.pop(context);
              if (widget.images.length <= 1) {
                Navigator.pop(context); // Close gallery if last image
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/presentation/widgets/image_gallery_view.dart
git commit -m "feat: add full-screen image gallery view with swipe and delete"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/presentation/widgets/meal_history_card.dart`

**Step 1: Update to show image count badge**

```dart
// In build method, wrap image with badge if multiple images
Stack(
  children: [
    Image.file(File(images.first.imagePath)),
    if (images.length > 1)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${images.length - 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
  ],
)
```

**Step 2: Commit**

```bash
git add lib/presentation/widgets/meal_history_card.dart
git commit -m "feat: show image count badge on meal history cards"
```

---

- [x] **COMPLETED**

**Files:**
- Modify: `lib/data/services/database_service.dart`

**Step 1: Verify foreign key constraints**

Ensure the `meal_images` table has `ON DELETE CASCADE` (already added in Task 3).

**Step 2: Add file cleanup when meal is deleted**

Update `MealRepository.deleteMeal` to also delete image files:

```dart
Future<void> deleteMeal(int id) async {
  // Get images before deleting meal
  final images = await _imageRepository.getImagesForMeal(id);
  
  // Delete meal (cascade deletes image rows)
  final db = await DatabaseService.database;
  await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  
  // Delete image files
  for (final image in images) {
    await ImageStorageService.deleteImage(image.imagePath);
  }
  
  await DatabaseService.notifyChange(table: 'meals');
}
```

**Step 3: Commit**

```bash
git add lib/data/repositories/meal_repository.dart
git commit -m "feat: cascade delete image files when meal is deleted"
```

---

- [x] **COMPLETED**

**Step 1: Run tests**

```bash
flutter test
```

**Step 2: Run on device**

```bash
flutter run
```

**Step 3: Manual test checklist**

- [x] Can add multiple images to a meal
- [x] Images display in meal slot
- [x] Can open gallery view and swipe
- [x] Can delete individual images
- [x] Deleting meal deletes all images
- [x] Images persist after app restart

**Step 4: Final commit**

```bash
git commit -m "feat: complete multi-image per meal implementation"
```

---

## Summary

### Files Created:
- `lib/data/models/meal_image.dart`
- `lib/data/repositories/meal_image_repository.dart`
- `lib/data/services/image_migration_service.dart`
- `lib/presentation/widgets/image_gallery_view.dart`

### Files Modified:
- `lib/data/services/database_service.dart` (schema + migration)
- `lib/data/services/image_storage_service.dart` (multi-image support)
- `lib/data/models/meal.dart` (remove single image)
- `lib/data/repositories/meal_repository.dart` (remove image handling)
- `lib/presentation/widgets/meal_slot.dart` (multi-image UI)
- `lib/presentation/widgets/meal_history_card.dart` (image count badge)
- `lib/main.dart` (migration trigger)

### Migration Process:
1. Build and run migration version (once)
2. Verify images migrated correctly
3. Switch to clean build (remove migration code)
4. Continue development with multi-image support
