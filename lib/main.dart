import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_scope.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/theme_scope.dart';
import 'theme/theme_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './stores/report_stores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final authService = AuthService();
  ReportsStore().auth = authService;
  await authService.restoreSession();

  final themeService = ThemeService();
  await themeService.load();

  runApp(ArisApp(auth: authService, themeService: themeService));
}

class ArisApp extends StatefulWidget {
  const ArisApp({super.key, required this.auth, required this.themeService});

  final AuthService auth;
  final ThemeService themeService;

  @override
  State<ArisApp> createState() => _ArisAppState();
}

class _ArisAppState extends State<ArisApp> {
  ThemeService get _themeService => widget.themeService;
  AuthService get _authService => widget.auth;

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
            final brightness = colors.mode == PaletteMode.dark
                ? Brightness.dark
                : Brightness.light;
            return MaterialApp(
              title: 'ARIS',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: colors.bgPrimary,
                textTheme: GoogleFonts.dmSansTextTheme(
                  ThemeData(brightness: brightness).textTheme,
                ),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: colors.accent,
                  brightness: brightness,
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
