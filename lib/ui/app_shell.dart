import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/absences_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/grades_provider.dart';
import '../providers/planning_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Main app shell that handles navigation based on auth state
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AuthProvider _auth;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>()..addListener(_onAuthChanged);
    // Initialize auth state
    WidgetsBinding.instance.addPostFrameCallback((_) => _auth.initialize());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Drop the previous user's data on logout / session expiry.
  void _onAuthChanged() {
    final isAuthenticated = _auth.isAuthenticated;
    if (_wasAuthenticated && !isAuthenticated) {
      context.read<PlanningProvider>().reset();
      context.read<GradesProvider>().reset();
      context.read<AbsencesProvider>().reset();
    }
    _wasAuthenticated = isAuthenticated;
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildScreen(auth.state),
        );
      },
    );
  }
  
  Widget _buildScreen(AuthState state) {
    switch (state) {
      case AuthState.initial:
      case AuthState.loading:
        return const SplashScreen();
        
      case AuthState.authenticated:
        return HomeScreen(
          onLogout: () {
            // Auth provider handles state change
          },
        );
        
      case AuthState.unauthenticated:
      case AuthState.error:
        return LoginScreen(
          onLoginSuccess: () {
            // Auth provider handles state change
          },
        );
    }
  }
}
