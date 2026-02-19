import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';

class MealSlotWidget extends StatelessWidget {
  final MealSlot slot;
  final Meal? meal;
  final String description;
  final bool isLoading;
  final VoidCallback? onCapturePhoto;
  final VoidCallback? onPickImage;
  final VoidCallback? onDeletePhoto;
  final VoidCallback? onClearMeal;
  final ValueChanged<String>? onDescriptionChanged;

  const MealSlotWidget({
    super.key,
    required this.slot,
    this.meal,
    this.description = '',
    this.isLoading = false,
    this.onCapturePhoto,
    this.onPickImage,
    this.onDeletePhoto,
    this.onClearMeal,
    this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildPhotoSection(context),
            const SizedBox(height: 12),
            _buildDescriptionInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(_getSlotIcon(), color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              slot.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (meal != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: onClearMeal,
            tooltip: 'Clear meal',
          ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (meal?.hasImage ?? false) {
      return _buildPhotoPreview(context);
    }

    return _buildPhotoPlaceholder(context);
  }

  Widget _buildPhotoPreview(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(meal!.imagePath!),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.error,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not found',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.edit,
                onTap: onCapturePhoto,
                tooltip: 'Replace photo',
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete,
                onTap: onDeletePhoto,
                tooltip: 'Delete photo',
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhotoButton(
            context: context,
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: onCapturePhoto,
          ),
          Container(
            width: 1,
            height: 60,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildPhotoButton(
            context: context,
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: onPickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red[300] : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: TextEditingController(text: description)
        ..selection = TextSelection.collapsed(offset: description.length),
      onChanged: onDescriptionChanged,
      maxLines: null,
      minLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Add a description (optional)...',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  IconData _getSlotIcon() {
    switch (slot) {
      case MealSlot.breakfast:
        return Icons.breakfast_dining;
      case MealSlot.lunch:
        return Icons.lunch_dining;
      case MealSlot.afternoonSnack:
        return Icons.coffee;
      case MealSlot.dinner:
        return Icons.dinner_dining;
    }
  }
}
