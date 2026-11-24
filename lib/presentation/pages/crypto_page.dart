import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/coin_entity.dart';
import '../blocs/crypto/crypto_bloc.dart';
import '../blocs/crypto/crypto_event.dart';
import '../blocs/crypto/crypto_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/mini_sparkline.dart';
import '../widgets/offline_banner.dart';
import '../widgets/theme_selector_sheet.dart';

class CryptoPage extends StatelessWidget {
  const CryptoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.cryptoTitle,
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
              context.read<CryptoBloc>().add(const LoadCoinsEvent(forceRefresh: true));
            },
          ),
        ],
      ),
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          return Column(
            children: [
              // Offline banner
              OfflineBanner(
                visible: state.isOffline,
                message: state.errorMessage ?? AppStrings.commonOfflineBanner,
                onRetry: () {
                  context.read<CryptoBloc>().add(const LoadCoinsEvent(forceRefresh: true));
                },
              ),

              // Hero Card
              _buildMarketHero(context, state.coins, currencyFormatter),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMedium,
                  vertical: AppDimensions.spacingSmall,
                ),
                child: TextField(
                  onChanged: (query) {
                    context.read<CryptoBloc>().add(SearchCoinsEvent(query));
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.cryptoSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Coin List or Empty/Loading state
              Expanded(
                child: _buildListContent(context, state, currencyFormatter),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarketHero(
    BuildContext context,
    List<CoinEntity> coins,
    NumberFormat formatter,
  ) {
    final theme = Theme.of(context);
    final btc = coins.where((c) => c.symbol == 'BTC').firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMedium,
        vertical: AppDimensions.spacingSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.heroMarketPulse,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppStrings.heroMarketSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                radius: 20,
                child: Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          if (btc != null) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BTC ${formatter.format(btc.currentPrice)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: btc.isPositiveChange
                        ? AppColors.marketGreenContainer
                        : AppColors.marketRedContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${btc.isPositiveChange ? '+' : ''}${btc.priceChangePercentage24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: btc.isPositiveChange
                          ? AppColors.marketGreen
                          : AppColors.marketRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    CryptoState state,
    NumberFormat formatter,
  ) {
    if (state.isLoading && state.displayList.isEmpty) {
      return const LoadingView();
    }
    if (state.displayList.isEmpty) {
      return EmptyStateView(
        onAction: () {
          context.read<CryptoBloc>().add(const LoadCoinsEvent(forceRefresh: true));
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CryptoBloc>().add(const LoadCoinsEvent(forceRefresh: true));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMedium,
          vertical: AppDimensions.spacingSmall,
        ),
        itemCount: state.displayList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final coin = state.displayList[index];
          return _buildCoinCard(context, coin, formatter);
        },
      ),
    );
  }

  Widget _buildCoinCard(
    BuildContext context,
    CoinEntity coin,
    NumberFormat formatter,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Row(
          children: [
            // Rank badge
            CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '${coin.rank}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),

            // Logo
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: AppDimensions.coinLogoSize,
                height: AppDimensions.coinLogoSize,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(coin.symbol.substring(0, 1)),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMedium),

            // Name & Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    coin.symbol,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Sparkline Graph
            if (coin.sparklinePoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: MiniSparkline(
                  points: coin.sparklinePoints,
                  isPositive: coin.isPositiveChange,
                ),
              ),

            const SizedBox(width: AppDimensions.spacingSmall),

            // Price & 24h Change Pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(coin.currentPrice),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: coin.isPositiveChange
                        ? AppColors.marketGreenContainer
                        : AppColors.marketRedContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${coin.isPositiveChange ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: coin.isPositiveChange
                          ? AppColors.marketGreen
                          : AppColors.marketRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
