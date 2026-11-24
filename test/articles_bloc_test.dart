import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:techhub_bloc/core/common/resource.dart';
import 'package:techhub_bloc/domain/entities/article_entity.dart';
import 'package:techhub_bloc/domain/usecases/get_articles_usecase.dart';
import 'package:techhub_bloc/domain/usecases/get_bookmarks_usecase.dart';
import 'package:techhub_bloc/domain/usecases/toggle_bookmark_usecase.dart';
import 'package:techhub_bloc/presentation/blocs/articles/articles_bloc.dart';
import 'package:techhub_bloc/presentation/blocs/articles/articles_event.dart';
import 'package:techhub_bloc/presentation/blocs/articles/articles_state.dart';

class MockGetArticlesUseCase extends Mock implements GetArticlesUseCase {}
class MockGetBookmarksUseCase extends Mock implements GetBookmarksUseCase {}
class MockToggleBookmarkUseCase extends Mock implements ToggleBookmarkUseCase {}

void main() {
  late MockGetArticlesUseCase mockGetArticlesUseCase;
  late MockGetBookmarksUseCase mockGetBookmarksUseCase;
  late MockToggleBookmarkUseCase mockToggleBookmarkUseCase;

  const sampleArticle = ArticleEntity(
    id: 101,
    title: 'Clean Architecture in Flutter',
    description: 'A deep dive into Clean Architecture with BLoC.',
    webUrl: 'https://dev.to/example',
    coverImageUrl: 'https://example.com/cover.png',
    publishedDate: '2026-11-24',
    readingTimeMinutes: 5,
    tags: ['flutter', 'bloc'],
    authorName: 'Mayank Patel',
    authorProfileImageUrl: 'https://example.com/user.png',
    isBookmarked: false,
  );

  setUp(() {
    mockGetArticlesUseCase = MockGetArticlesUseCase();
    mockGetBookmarksUseCase = MockGetBookmarksUseCase();
    mockToggleBookmarkUseCase = MockToggleBookmarkUseCase();
  });

  group('ArticlesBloc Tests', () {
    test('initial state has empty articles and isLoading false', () {
      final bloc = ArticlesBloc(
        getArticlesUseCase: mockGetArticlesUseCase,
        getBookmarksUseCase: mockGetBookmarksUseCase,
        toggleBookmarkUseCase: mockToggleBookmarkUseCase,
      );
      expect(bloc.state.articles, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });

    blocTest<ArticlesBloc, ArticlesState>(
      'emits [Loading, Success] when LoadArticlesEvent is added',
      build: () {
        when(() => mockGetBookmarksUseCase()).thenReturn(<ArticleEntity>[]);
        when(() => mockGetArticlesUseCase(forceRefresh: false)).thenAnswer(
          (_) => Stream.fromIterable([
            const ResourceLoading<List<ArticleEntity>>(),
            const ResourceSuccess<List<ArticleEntity>>([sampleArticle]),
          ]),
        );
        return ArticlesBloc(
          getArticlesUseCase: mockGetArticlesUseCase,
          getBookmarksUseCase: mockGetBookmarksUseCase,
          toggleBookmarkUseCase: mockToggleBookmarkUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoadArticlesEvent(forceRefresh: false)),
      expect: () => [
        const ArticlesState(isLoading: false, articles: [], bookmarkedArticles: [], errorMessage: null),
        const ArticlesState(isLoading: true, articles: [], bookmarkedArticles: [], errorMessage: null),
        const ArticlesState(isLoading: false, articles: [sampleArticle], bookmarkedArticles: [], errorMessage: null),
      ],
    );
  });
}
