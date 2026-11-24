import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_strings.dart';
import 'core/database/hive_service.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'presentation/blocs/articles/articles_bloc.dart';
import 'presentation/blocs/articles/articles_event.dart';
import 'presentation/blocs/crypto/crypto_bloc.dart';
import 'presentation/blocs/crypto/crypto_event.dart';
import 'presentation/blocs/interview/interview_bloc.dart';
import 'presentation/pages/main_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive Local Database
  await HiveService.init();

  // 2. Initialize Service Locator & Dependencies
  await initDependencies();

  runApp(const TechHubBlocApp());
}

class TechHubBlocApp extends StatelessWidget {
  const TechHubBlocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<CryptoBloc>(
          create: (_) => sl<CryptoBloc>()..add(const LoadCoinsEvent()),
        ),
        BlocProvider<ArticlesBloc>(
          create: (_) => sl<ArticlesBloc>()..add(const LoadArticlesEvent()),
        ),
        BlocProvider<InterviewBloc>(create: (_) => sl<InterviewBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(
              palette: themeState.palette,
              isDark: false,
            ),
            darkTheme: AppTheme.getTheme(
              palette: themeState.palette,
              isDark: true,
            ),
            themeMode: themeState.mode == ThemeModeType.system
                ? ThemeMode.system
                : (themeState.mode == ThemeModeType.dark
                    ? ThemeMode.dark
                    : ThemeMode.light),
            home: const MainNavigationPage(),
          );
        },
      ),
    );
  }
}
