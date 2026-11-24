import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:techhub_bloc/core/common/resource.dart';
import 'package:techhub_bloc/domain/entities/coin_entity.dart';
import 'package:techhub_bloc/domain/usecases/get_coins_usecase.dart';
import 'package:techhub_bloc/domain/usecases/search_coins_usecase.dart';
import 'package:techhub_bloc/presentation/blocs/crypto/crypto_bloc.dart';
import 'package:techhub_bloc/presentation/blocs/crypto/crypto_event.dart';
import 'package:techhub_bloc/presentation/blocs/crypto/crypto_state.dart';

class MockGetCoinsUseCase extends Mock implements GetCoinsUseCase {}
class MockSearchCoinsUseCase extends Mock implements SearchCoinsUseCase {}

void main() {
  late MockGetCoinsUseCase mockGetCoinsUseCase;
  late MockSearchCoinsUseCase mockSearchCoinsUseCase;

  const sampleCoin = CoinEntity(
    id: 'bitcoin',
    symbol: 'BTC',
    name: 'Bitcoin',
    imageUrl: 'https://example.com/btc.png',
    currentPrice: 90000.0,
    marketCap: 1800000000000,
    rank: 1,
    totalVolume: 40000000000.0,
    high24h: 91000.0,
    low24h: 89000.0,
    priceChangePercentage24h: 2.5,
    sparklinePoints: [89000.0, 90000.0],
  );

  setUp(() {
    mockGetCoinsUseCase = MockGetCoinsUseCase();
    mockSearchCoinsUseCase = MockSearchCoinsUseCase();
  });

  group('CryptoBloc Tests', () {
    test('initial state has empty coins and isLoading false', () {
      final bloc = CryptoBloc(
        getCoinsUseCase: mockGetCoinsUseCase,
        searchCoinsUseCase: mockSearchCoinsUseCase,
      );
      expect(bloc.state.coins, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });

    blocTest<CryptoBloc, CryptoState>(
      'emits [Loading, Success] when LoadCoinsEvent is added',
      build: () {
        when(() => mockGetCoinsUseCase(forceRefresh: false)).thenAnswer(
          (_) => Stream.fromIterable([
            const ResourceLoading<List<CoinEntity>>(),
            const ResourceSuccess<List<CoinEntity>>([sampleCoin]),
          ]),
        );
        return CryptoBloc(
          getCoinsUseCase: mockGetCoinsUseCase,
          searchCoinsUseCase: mockSearchCoinsUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoadCoinsEvent(forceRefresh: false)),
      expect: () => [
        const CryptoState(isLoading: true, coins: [], errorMessage: null),
        const CryptoState(isLoading: false, coins: [sampleCoin], errorMessage: null),
      ],
    );

    blocTest<CryptoBloc, CryptoState>(
      'emits [Error] with cached coins when network fails',
      build: () {
        when(() => mockGetCoinsUseCase(forceRefresh: true)).thenAnswer(
          (_) => Stream.fromIterable([
            const ResourceLoading<List<CoinEntity>>(data: [sampleCoin]),
            const ResourceError<List<CoinEntity>>('Offline', data: [sampleCoin]),
          ]),
        );
        return CryptoBloc(
          getCoinsUseCase: mockGetCoinsUseCase,
          searchCoinsUseCase: mockSearchCoinsUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoadCoinsEvent(forceRefresh: true)),
      expect: () => [
        const CryptoState(isLoading: true, isRefreshing: true, coins: [sampleCoin]),
        const CryptoState(isLoading: false, isRefreshing: false, isOffline: true, coins: [sampleCoin], errorMessage: 'Offline'),
      ],
    );
  });
}
