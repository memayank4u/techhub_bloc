import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLarge),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.themeDialogTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),

                // Palette Section
                Text(
                  AppStrings.themePaletteLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),

                Row(
                  children: [
                    _buildPaletteOption(
                      context: context,
                      title: AppStrings.themePaletteCobalt,
                      color: AppColors.cobaltPrimaryLight,
                      isSelected: themeState.palette == ColorPalette.cobalt,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updatePalette(ColorPalette.cobalt),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    _buildPaletteOption(
                      context: context,
                      title: AppStrings.themePaletteEmerald,
                      color: AppColors.emeraldPrimaryLight,
                      isSelected: themeState.palette == ColorPalette.emerald,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updatePalette(ColorPalette.emerald),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    _buildPaletteOption(
                      context: context,
                      title: AppStrings.themePaletteAmethyst,
                      color: AppColors.amethystPrimaryLight,
                      isSelected: themeState.palette == ColorPalette.amethyst,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updatePalette(ColorPalette.amethyst),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacingLarge),

                // Theme Mode Section
                Text(
                  AppStrings.themeModeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),

                Row(
                  children: [
                    _buildModeChip(
                      context: context,
                      label: AppStrings.themeModeSystem,
                      isSelected: themeState.mode == ThemeModeType.system,
                      onSelected: () => context
                          .read<ThemeCubit>()
                          .updateMode(ThemeModeType.system),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    _buildModeChip(
                      context: context,
                      label: AppStrings.themeModeLight,
                      isSelected: themeState.mode == ThemeModeType.light,
                      onSelected: () => context
                          .read<ThemeCubit>()
                          .updateMode(ThemeModeType.light),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    _buildModeChip(
                      context: context,
                      label: AppStrings.themeModeDark,
                      isSelected: themeState.mode == ThemeModeType.dark,
                      onSelected: () => context
                          .read<ThemeCubit>()
                          .updateMode(ThemeModeType.dark),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaletteOption({
    required BuildContext context,
    required String title,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 14,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}
