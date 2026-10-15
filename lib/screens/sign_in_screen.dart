import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_scope.dart';
import '../services/auth_service.dart';
import '../theme/theme_scope.dart';

abstract final class _Hero {
  static const bg = Color(0xFF0B1A10);
  static const glow = Color(0xFF1F4A2C);
  static const tile = Color(0xFF16261B);
  static const headline = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA9C4B0);
  static const subtle = Color(0xFF7FA088);
}

const String _heroHeadline = 'Your records,\nwith clarity.';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);
    final isLoading = auth.status == AuthStatus.authenticating;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons because the top of the screen is dark green.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Hero.bg,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const Expanded(child: _HeroPanel()),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 28 + bottomInset),
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: GoogleFonts.dmSans(
                            color: colors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue with your institution account.',
                          style: GoogleFonts.dmSans(
                            color: colors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (auth.error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              auth.error!,
                              style: GoogleFonts.dmSans(
                                color: colors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: colors.accentActive.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : auth.signInWithOAuth,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: colors.accentActive,
                                disabledBackgroundColor: colors.accentActive
                                    .withValues(alpha: 0.6),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  : const Text('Continue with Google'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            "Sign-in uses your institution's single sign-on account.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark green top section: soft radial glow, logo tile, headline, tagline.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            right: -140,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _Hero.glow.withValues(alpha: 0.7),
                    _Hero.glow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _Hero.tile,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('assets/aris_icon.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARIS',
                              style: GoogleFonts.dmSans(
                                color: _Hero.headline,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Academic Report & Information System',
                              style: GoogleFonts.dmSans(
                                color: _Hero.subtle,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _heroHeadline,
                    style: GoogleFonts.dmSans(
                      color: _Hero.headline,
                      fontSize: 36,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Track your Accomplishment Reports and DTR status in one place.',
                    style: GoogleFonts.dmSans(
                      color: _Hero.muted,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}