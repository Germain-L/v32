import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_image.dart';
import '../../utils/l10n_helper.dart';
import '../../utils/date_formatter.dart';

class MealHistoryCard extends StatelessWidget {
  final Meal meal;
  final List<MealImage> images;
  final VoidCallback? onTap;

  const MealHistoryCard({
    super.key,
    required this.meal,
    this.images = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, colorScheme),
              const SizedBox(height: 8),
              if (meal.hasImage) ...[
                _buildImagePreview(context),
                if (meal.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _buildCaption(theme, colorScheme),
                ],
              ] else
                _buildTextOnlyPreview(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          Icon(_getSlotIcon(meal.slot), size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            meal.slot.localizedName(context.l10n),
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            context.dateFormatter.formatTime(meal.date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (meal.hasImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.file(
                File(meal.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(colorScheme);
                },
              ),
            ),
          ),
          if (images.isNotEmpty && images.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Center(
          child: Icon(
            Icons.restaurant_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Text(
        meal.description!,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildTextOnlyPreview(ThemeData theme, ColorScheme colorScheme) {
    final hasCaption = meal.description?.isNotEmpty == true;

    if (!hasCaption) {
      return _buildPlaceholder(colorScheme);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Text(
        meal.description!,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  IconData _getSlotIcon(MealSlot slot) {
    return switch (slot) {
      MealSlot.breakfast => Icons.wb_sunny_outlined,
      MealSlot.lunch => Icons.lunch_dining_outlined,
      MealSlot.afternoonSnack => Icons.coffee_outlined,
      MealSlot.dinner => Icons.nights_stay_outlined,
    };
  }
}
