import 'package:equatable/equatable.dart';

abstract class ArticlesEvent extends Equatable {
  const ArticlesEvent();

  @override
  List<Object?> get props => [];
}

class LoadArticlesEvent extends ArticlesEvent {
  final bool forceRefresh;
  const LoadArticlesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SelectArticleTabEvent extends ArticlesEvent {
  final int tabIndex; // 0 = Latest, 1 = Bookmarks
  const SelectArticleTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class ToggleBookmarkEvent extends ArticlesEvent {
  final int articleId;
  final bool isBookmarked;

  const ToggleBookmarkEvent({
    required this.articleId,
    required this.isBookmarked,
  });

  @override
  List<Object?> get props => [articleId, isBookmarked];
}
