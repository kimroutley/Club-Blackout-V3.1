import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';

import 'data/role_repository.dart';
import 'logic/game_engine.dart';
import 'logic/games_night_service.dart';
import 'services/dynamic_theme_service.dart';
import 'ui/screens/main_screen.dart';
import 'ui/scroll_behavior.dart';
import 'ui/styles.dart';
import 'ui/utils/error_handler.dart';
import 'utils/game_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pixel 10 Pro Edge-to-Edge Design
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    GameLogger.info('System UI initialized', context: 'Main');
  } catch (e, stackTrace) {
    GameLogger.error('System chrome initialization failed',
        context: 'Main', error: e, stackTrace: stackTrace);
  }

  try {
    await GamesNightService.instance.loadFromPrefs();
    GameLogger.info('Games Night session restored (if present)',
        context: 'Main');
  } catch (e, stackTrace) {
    GameLogger.error(
      'Games Night restore failed (continuing)',
      context: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Request high refresh rate (120Hz+) if supported by device
  try {
    await FlutterDisplayMode.setHighRefreshRate();
    GameLogger.info('High refresh rate requested', context: 'Main');
  } catch (e) {
    GameLogger.error('Failed to set high refresh rate',
        context: 'Main', error: e);
  }

  // Enforce Portrait Mode
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (e) {
    debugPrint('Failed to set orientation: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DynamicThemeService()),
      ],
      child: const ClubBlackoutApp(),
    ),
  );
}

class ClubBlackoutApp extends StatefulWidget {
  const ClubBlackoutApp({super.key});

  @override
  State<ClubBlackoutApp> createState() => _ClubBlackoutAppState();
}

class _ClubBlackoutAppState extends State<ClubBlackoutApp> {
  final RoleRepository _roleRepo = RoleRepository();
  GameEngine? _engine;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      GameLogger.info('Init started', context: 'Main');
      await _roleRepo.loadRoles();
      GameLogger.info('Creating GameEngine', context: 'Main');
      setState(() => _engine = GameEngine(roleRepository: _roleRepo));

      // Initialize default theme from home background
      final themeService = DynamicThemeService();
      await themeService.updateFromBackground(
        'Backgrounds/Club Blackout V2 Home Menu.png',
      );

      GameLogger.info('Init complete', context: 'Main');
    } catch (e) {
      GameLogger.error('Init failed', context: 'Main', error: e);
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final themeService = Provider.of<DynamicThemeService>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use dynamic theme service colors if available, otherwise fall back
        final lightScheme = themeService.lightScheme ??
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: ClubBlackoutTheme.neonPurple,
              brightness: Brightness.light,
            );

        final darkScheme = themeService.darkScheme ??
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: ClubBlackoutTheme.neonPurple,
              brightness: Brightness.dark,
              surface: ClubBlackoutTheme.kBackground, // Ensure surface matches background in seed
              background: ClubBlackoutTheme.kBackground,
            );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Club Blackout',
          theme: ClubBlackoutTheme.createTheme(lightScheme).copyWith(
            scaffoldBackgroundColor: ClubBlackoutTheme.kBackground,
          ),
          darkTheme: ClubBlackoutTheme.createTheme(darkScheme).copyWith(
            scaffoldBackgroundColor: ClubBlackoutTheme.kBackground,
          ),
          themeMode: ThemeMode.dark,
          scrollBehavior: const ClubBlackoutScrollBehavior(),
          home: _error != null
              ? _ErrorSummaryScreen(
                  error: _error!,
                  onRetry: () {
                    setState(() {
                      _error = null;
                      _engine = null;
                    });
                    _init();
                  },
                )
              : engine == null
                  ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()))
                  : MainScreen(gameEngine: engine),
        );
      },
    );
  }
}

/// A clean error summary screen for fatal initialization errors
class _ErrorSummaryScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorSummaryScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Club Blackout couldn\'t start properly. This usually happens if data files are missing or corrupted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  ErrorHandler.showErrorDialog(
                    context: context,
                    title: 'Error Details',
                    message: error.toString(),
                    onRetry: onRetry,
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Show Details & Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
