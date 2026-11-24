import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/article_entity.dart';
import '../blocs/articles/articles_bloc.dart';
import '../blocs/articles/articles_event.dart';
import '../blocs/articles/articles_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/offline_banner.dart';
import '../widgets/theme_selector_sheet.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.articlesTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: AppStrings.themeSettingsTooltip,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const ThemeSelectorSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.commonRefresh,
            onPressed: () {
              context.read<ArticlesBloc>().add(const LoadArticlesEvent(forceRefresh: true));
            },
          ),
        ],
      ),
      body: BlocBuilder<ArticlesBloc, ArticlesState>(
        builder: (context, state) {
          return Column(
            children: [
              // Tab Selector (Latest vs Saved Bookmarks)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMedium,
                  vertical: AppDimensions.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      context: context,
                      title: AppStrings.articlesTabAll,
                      isSelected: state.selectedTab == 0,
                      onTap: () {
                        context.read<ArticlesBloc>().add(const SelectArticleTabEvent(0));
                      },
                    ),
                    _buildTabButton(
                      context: context,
                      title: AppStrings.articlesTabSaved,
                      isSelected: state.selectedTab == 1,
                      onTap: () {
                        context.read<ArticlesBloc>().add(const SelectArticleTabEvent(1));
                      },
                    ),
                  ],
                ),
              ),

              // Offline Banner
              OfflineBanner(
                visible: state.isOffline,
                message: state.errorMessage ?? AppStrings.commonOfflineBanner,
                onRetry: () {
                  context.read<ArticlesBloc>().add(const LoadArticlesEvent(forceRefresh: true));
                },
              ),

              // Article List Content
              Expanded(
                child: _buildArticlesList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesList(BuildContext context, ArticlesState state) {
    if (state.isLoading && state.displayList.isEmpty) {
      return const LoadingView();
    }
    if (state.displayList.isEmpty) {
      if (state.selectedTab == 1) {
        return const EmptyStateView(
          icon: Icons.bookmark_border,
          title: AppStrings.articlesEmptyBookmarks,
          subtitle: AppStrings.articlesEmptyBookmarksSub,
          actionText: null,
        );
      }
      return EmptyStateView(
        onAction: () {
          context.read<ArticlesBloc>().add(const LoadArticlesEvent(forceRefresh: true));
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ArticlesBloc>().add(const LoadArticlesEvent(forceRefresh: true));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMedium,
          vertical: AppDimensions.spacingSmall,
        ),
        itemCount: state.displayList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = state.displayList[index];
          return _buildArticleCard(context, article);
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleEntity article) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(article.webUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Gradient Scrim
            if (article.coverImageUrl != null && article.coverImageUrl!.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    article.coverImageUrl!,
                    height: AppDimensions.articleCoverHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author & Bookmark button
                  Row(
                    children: [
                      if (article.authorProfileImageUrl != null &&
                          article.authorProfileImageUrl!.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            article.authorProfileImageUrl!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 24),
                          ),
                        ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.authorName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              article.publishedDate,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          article.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: article.isBookmarked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          context.read<ArticlesBloc>().add(ToggleBookmarkEvent(
                                articleId: article.id,
                                isBookmarked: article.isBookmarked,
                              ));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingSmall),

                  // Title
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingXSmall),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // Tags
                  if (article.tags.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingSmall),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: article.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.spacingSmall),

                  // Reading time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readingTimeMinutes} min read',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
