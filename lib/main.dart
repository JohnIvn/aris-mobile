import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_scope.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/theme_scope.dart';
import 'theme/theme_service.dart';

void main() {
  runApp(const ArisApp());
}

class ArisApp extends StatefulWidget {
  const ArisApp({super.key});

  @override
  State<ArisApp> createState() => _ArisAppState();
}

class _ArisAppState extends State<ArisApp> {
  final ThemeService _themeService = ThemeService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      themeService: _themeService,
      child: AuthScope(
        authService: _authService,
        child: AnimatedBuilder(
          animation: Listenable.merge([_themeService, _authService]),
          builder: (context, _) {
            final colors = _themeService.colors;
            return MaterialApp(
              title: 'ARIS',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: colors.bgPrimary,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: colors.accent,
                  brightness: colors.mode == PaletteMode.dark
                      ? Brightness.dark
                      : Brightness.light,
                ),
              ),
              home: _authService.status == AuthStatus.authenticated
                  ? const RootShell()
                  : const SignInScreen(),
            );
          },
        ),
      ),
    );
  }
}
