import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/common/resource.dart';
import '../../../domain/usecases/get_coins_usecase.dart';
import '../../../domain/usecases/search_coins_usecase.dart';
import 'crypto_event.dart';
import 'crypto_state.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final GetCoinsUseCase getCoinsUseCase;
  final SearchCoinsUseCase searchCoinsUseCase;

  CryptoBloc({
    required this.getCoinsUseCase,
    required this.searchCoinsUseCase,
  }) : super(const CryptoState()) {
    on<LoadCoinsEvent>(_onLoadCoins);
    on<SearchCoinsEvent>(_onSearchCoins);
  }

  Future<void> _onLoadCoins(
    LoadCoinsEvent event,
    Emitter<CryptoState> emit,
  ) async {
    await emit.forEach(
      getCoinsUseCase(forceRefresh: event.forceRefresh),
      onData: (resource) {
        if (resource is ResourceLoading) {
          return state.copyWith(
            isLoading: state.coins.isEmpty,
            isRefreshing: event.forceRefresh,
            coins: resource.data ?? state.coins,
            errorMessage: null,
          );
        } else if (resource is ResourceSuccess) {
          return state.copyWith(
            isLoading: false,
            isRefreshing: false,
            isOffline: false,
            coins: resource.data ?? [],
            errorMessage: null,
          );
        } else if (resource is ResourceError) {
          return state.copyWith(
            isLoading: false,
            isRefreshing: false,
            isOffline: true,
            coins: resource.data ?? state.coins,
            errorMessage: resource.message,
          );
        }
        return state;
      },
    );
  }

  void _onSearchCoins(
    SearchCoinsEvent event,
    Emitter<CryptoState> emit,
  ) {
    final query = event.query;
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredCoins: []));
    } else {
      final filtered = searchCoinsUseCase(query);
      emit(state.copyWith(searchQuery: query, filteredCoins: filtered));
    }
  }
}
