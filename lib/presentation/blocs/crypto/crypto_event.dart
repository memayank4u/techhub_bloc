import 'package:equatable/equatable.dart';

abstract class CryptoEvent extends Equatable {
  const CryptoEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoinsEvent extends CryptoEvent {
  final bool forceRefresh;
  const LoadCoinsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SearchCoinsEvent extends CryptoEvent {
  final String query;
  const SearchCoinsEvent(this.query);

  @override
  List<Object?> get props => [query];
}
