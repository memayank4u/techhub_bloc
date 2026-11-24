import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/common/resource.dart';
import '../../../domain/usecases/get_articles_usecase.dart';
import '../../../domain/usecases/get_bookmarks_usecase.dart';
import '../../../domain/usecases/toggle_bookmark_usecase.dart';
import 'articles_event.dart';
import 'articles_state.dart';

class ArticlesBloc extends Bloc<ArticlesEvent, ArticlesState> {
  final GetArticlesUseCase getArticlesUseCase;
  final GetBookmarksUseCase getBookmarksUseCase;
  final ToggleBookmarkUseCase toggleBookmarkUseCase;

  ArticlesBloc({
    required this.getArticlesUseCase,
    required this.getBookmarksUseCase,
    required this.toggleBookmarkUseCase,
  }) : super(const ArticlesState()) {
    on<LoadArticlesEvent>(_onLoadArticles);
    on<SelectArticleTabEvent>(_onSelectTab);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
  }

  Future<void> _onLoadArticles(
    LoadArticlesEvent event,
    Emitter<ArticlesState> emit,
  ) async {
    final bookmarks = getBookmarksUseCase();
    emit(state.copyWith(bookmarkedArticles: bookmarks));

    await emit.forEach(
      getArticlesUseCase(forceRefresh: event.forceRefresh),
      onData: (resource) {
        if (resource is ResourceLoading) {
          return state.copyWith(
            isLoading: state.articles.isEmpty,
            isRefreshing: event.forceRefresh,
            articles: resource.data ?? state.articles,
            errorMessage: null,
          );
        } else if (resource is ResourceSuccess) {
          return state.copyWith(
            isLoading: false,
            isRefreshing: false,
            isOffline: false,
            articles: resource.data ?? [],
            errorMessage: null,
          );
        } else if (resource is ResourceError) {
          return state.copyWith(
            isLoading: false,
            isRefreshing: false,
            isOffline: true,
            articles: resource.data ?? state.articles,
            errorMessage: resource.message,
          );
        }
        return state;
      },
    );
  }

  void _onSelectTab(
    SelectArticleTabEvent event,
    Emitter<ArticlesState> emit,
  ) {
    final bookmarks = getBookmarksUseCase();
    emit(state.copyWith(
      selectedTab: event.tabIndex,
      bookmarkedArticles: bookmarks,
    ));
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<ArticlesState> emit,
  ) async {
    final newBookmarkedState = !event.isBookmarked;
    await toggleBookmarkUseCase(event.articleId, newBookmarkedState);

    // Update in memory
    final updatedArticles = state.articles.map((a) {
      if (a.id == event.articleId) {
        return a.copyWith(isBookmarked: newBookmarkedState);
      }
      return a;
    }).toList();

    final updatedBookmarks = getBookmarksUseCase();

    emit(state.copyWith(
      articles: updatedArticles,
      bookmarkedArticles: updatedBookmarks,
    ));
  }
}
