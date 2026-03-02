import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/meal_image.dart';
import 'haptic_feedback_wrapper.dart';
import 'press_scale.dart';

/// A reusable widget that displays meal images in a horizontal scrollable list
/// with an option to add more images.
class MealImageGallery extends StatelessWidget {
  final List<MealImage> images;
  final VoidCallback? onAddImage;
  final Function(int imageId)? onDeleteImage;
  final double height;

  const MealImageGallery({
    super.key,
    required this.images,
    this.onAddImage,
    this.onDeleteImage,
    this.height = 90,
  });

  static const double _thumbnailSize = 80;
  static const double _borderRadius = 8;
  static const double _spacing = 8;
  static const double _deleteButtonSize = 24;
  static const double _deleteIconSize = 16;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length + (onAddImage != null ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(width: _spacing),
        itemBuilder: (context, index) {
          if (index < images.length) {
            return _buildImageThumbnail(context, images[index], colorScheme);
          }
          return _buildAddButton(context, colorScheme);
        },
      ),
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    MealImage image,
    ColorScheme colorScheme,
  ) {
    return PressScale(
      onTap: () {
        // Could be used for viewing full image in future
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Image.file(
              File(image.imagePath),
              width: _thumbnailSize,
              height: _thumbnailSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.error,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          if (onDeleteImage != null && image.id != null)
            Positioned(
              top: 4,
              right: 4,
              child: _buildDeleteButton(context, image.id!, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    int imageId,
    ColorScheme colorScheme,
  ) {
    return PressScale(
      onTap: () {
        HapticFeedbackUtil.trigger(HapticLevel.medium);
        onDeleteImage?.call(imageId);
      },
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(_deleteButtonSize / 2),
        child: InkWell(
          onTap: () {
            HapticFeedbackUtil.trigger(HapticLevel.medium);
            onDeleteImage?.call(imageId);
          },
          borderRadius: BorderRadius.circular(_deleteButtonSize / 2),
          child: Container(
            width: _deleteButtonSize,
            height: _deleteButtonSize,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: _deleteIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme colorScheme) {
    return PressScale(
      onTap: () {
        HapticFeedbackUtil.trigger(HapticLevel.selection);
        onAddImage?.call();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedbackUtil.trigger(HapticLevel.selection);
            onAddImage?.call();
          },
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Container(
            width: _thumbnailSize,
            height: _thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.add, color: colorScheme.primary, size: 32),
          ),
        ),
      ),
    );
  }
}
