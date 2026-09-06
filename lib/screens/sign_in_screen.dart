import 'package:flutter/material.dart';

import 'package:oauth2/oauth2.dart' as oauth2;

import 'dart:async';
import 'dart:io';

import '../services/auth_scope.dart';
import '../services/auth_service.dart';
import '../theme/theme_scope.dart';

import 'package:flutter_svg/flutter_svg.dart';

final authorizationEndpoint = Uri.parse(
  'http://example.com/oauth2/authorization',
);
final tokenEndpoint = Uri.parse('http://example.com/oauth2/token');

const identifier = 'my client identifier';
const secret = 'my client secret';

final redirectUrl = Uri.parse('http://my-site.com/oauth2-redirect');

final credentialsFile = File('~/.myapp/credentials.json');

Future<oauth2.Client> createClient() async {
  var exists = await credentialsFile.exists();

  // If the OAuth2 credentials have already been saved from a previous run, we
  // just want to reload them.
  if (exists) {
    var credentials = oauth2.Credentials.fromJson(
      await credentialsFile.readAsString(),
    );
    return oauth2.Client(credentials, identifier: identifier, secret: secret);
  }

  // If we don't have OAuth2 credentials yet, we need to get the resource owner
  // to authorize us. We're assuming here that we're a command-line application.
  var grant = oauth2.AuthorizationCodeGrant(
    identifier,
    authorizationEndpoint,
    tokenEndpoint,
    secret: secret,
  );

  // A URL on the authorization server (authorizationEndpoint with some
  // additional query parameters). Scopes and state can optionally be passed
  // into this method.
  var authorizationUrl = grant.getAuthorizationUrl(redirectUrl);

  // Redirect the resource owner to the authorization URL. Once the resource
  // owner has authorized, they'll be redirected to `redirectUrl` with an
  // authorization code. The `redirect` should cause the browser to redirect to
  // another URL which should also have a listener.
  //
  // `redirect` and `listen` are not shown implemented here.
  await redirect(authorizationUrl);
  var responseUrl = await listen(redirectUrl);

  // Once the user is redirected to `redirectUrl`, pass the query parameters to
  // the AuthorizationCodeGrant. It will validate them and extract the
  // authorization code to create a new Client.
  return grant.handleAuthorizationResponse(responseUrl.queryParameters);
}

void main() async {
  var client = await createClient();

  // Once you have a Client, you can use it just like any other HTTP client.
  print(await client.read(Uri.http('example.com', 'protected-resources.txt')));

  // Once we're done with the client, save the credentials file. This ensures
  // that if the credentials were automatically refreshed while using the
  // client, the new credentials are available for the next run of the
  // program.
  await credentialsFile.writeAsString(client.credentials.toJson());
}

Future<void> redirect(Uri url) async {
  // Client implementation detail
}

Future<Uri> listen(Uri url) async {
  // Client implementation detail
  return Uri();
}

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
              SvgPicture.asset('assets/aris_title.svg', width: 72, height: 72),
              const SizedBox(height: 20),
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
                    disabledBackgroundColor: colors.accent.withValues(
                      alpha: 0.6,
                    ),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
