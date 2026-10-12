import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/grades_service.dart';
import 'data/services/home_widget_service.dart';
import 'data/services/planning_service.dart';
import 'data/services/absences_service.dart';
import 'data/services/token_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/grades_provider.dart';
import 'providers/planning_provider.dart';
import 'providers/absences_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/app_shell.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Day/month names for every locale (French dates in the planning).
  await initializeDateFormatting();

  // Initialize home screen widget support
  HomeWidgetService.initialize();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make Flutter draw behind the system navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const StudentApp());
}

/// Main application widget
class StudentApp extends StatefulWidget {
  const StudentApp({super.key});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  // Services - created once and shared across providers
  late final ApiClient _apiClient;
  late final TokenStorage _tokenStorage;
  late final AuthService _authService;
  late final PlanningService _planningService;
  late final GradesService _gradesService;
  late final AbsencesService _absencesService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _apiClient = ApiClient();
    _tokenStorage = TokenStorage();
    _authService = AuthService(
      apiClient: _apiClient,
      tokenStorage: _tokenStorage,
    );
    _planningService = PlanningService(apiClient: _apiClient);
    _gradesService = GradesService(apiClient: _apiClient);
    _absencesService = AbsencesService(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _authService.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: _authService),
        ),
        ChangeNotifierProvider(
          create: (_) => PlanningProvider(planningService: _planningService),
        ),
        ChangeNotifierProvider(
          create: (_) => GradesProvider(gradesService: _gradesService),
        ),
        ChangeNotifierProvider(
          create: (_) => AbsencesProvider(absencesService: _absencesService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: settings.strings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // Follow the system until the saved preference is read.
            themeMode: settings.isInitialized
                ? settings.themeMode
                : ThemeMode.system,
            // Below MaterialApp, so it sees the theme actually displayed,
            // including system light/dark changes while the app is open.
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final iconBrightness = isDark
                  ? Brightness.light
                  : Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: iconBrightness,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: iconBrightness,
                ),
                child: child!,
              );
            },
            home: const _Root(),
          );
        },
      ),
    );
  }
}

/// Splash until the settings are read, then the app. Same splash as the one
/// AppShell shows while restoring the session, so startup is seamless.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return context.watch<SettingsProvider>().isInitialized
        ? const AppShell()
        : const SplashScreen();
  }
}
