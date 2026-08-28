import 'package:flutter/material.dart';

import '../services/auth_scope.dart';
import '../services/auth_service.dart';
import '../theme/theme_scope.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);
    final isLoading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.fact_check_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'ARIS',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your Accomplishment Reports and DTR status in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),
              if (auth.error != null) ...[
                Text(
                  auth.error!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : auth.signInWithOAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    disabledBackgroundColor: colors.accent.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue with OAuth'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sign-in uses your institution's single sign-on account.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
