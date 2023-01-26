import 'package:busfare/views/home_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'controller/qr_controller.dart';
import 'decoration.dart';
import 'firebase_options.dart';

final actionCodeSettings = ActionCodeSettings(
  url: 'https://bus-fare-qr.firebaseapp.com',
  handleCodeInApp: true,
  androidMinimumVersion: '1',
  androidPackageName: packageName,
  iOSBundleId: packageName,
);
// final emailLinkProviderConfig = EmailLinkAuthProvider(
//   actionCodeSettings: actionCodeSettings,
// );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    PhoneAuthProvider(),
    GoogleProvider(clientId: googleClientId),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String get initialRoute {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null || auth.currentUser!.isAnonymous) {
      return '/';
    }

    if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
      return '/verify-email';
    }

    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // final mfaAction = AuthStateChangeAction<MFARequired>(
    //   (context, state) async {
    //     final nav = Navigator.of(context);

    //     await startMFAVerification(
    //       resolver: state.resolver,
    //       context: context,
    //     );

    //     nav.pushReplacementNamed('/profile');
    //   },
    // );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QrResultsProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          visualDensity: VisualDensity.standard,
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
          textButtonTheme: TextButtonThemeData(style: buttonStyle),
          outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
        ),
        initialRoute: initialRoute,
        routes: {
          '/': (context) {
            return SignInScreen(
              actions: [
                ForgotPasswordAction((context, email) {
                  Navigator.pushNamed(
                    context,
                    '/forgot-password',
                    arguments: {'email': email},
                  );
                }),
                VerifyPhoneAction((context, _) {
                  Navigator.pushNamed(context, '/phone');
                }),
                AuthStateChangeAction<SignedIn>((context, state) {
                  if (!(state.user?.emailVerified ?? false)) {
                    Navigator.pushNamed(context, '/verify-email');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }),
                AuthStateChangeAction<UserCreated>((context, state) {
                  if (!(state.credential.user?.emailVerified ?? false)) {
                    Navigator.pushNamed(context, '/verify-email');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }),
                AuthStateChangeAction<CredentialLinked>((context, state) {
                  if (!state.user.emailVerified) {
                    Navigator.pushNamed(context, '/verify-email');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }),
                // mfaAction,
                EmailLinkSignInAction((context) {
                  Navigator.pushReplacementNamed(
                      context, '/email-link-sign-in');
                }),
              ],
              styles: const {
                EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
              },
              headerBuilder: headerImage('assets/icons/blue_logo.png'),
              sideBuilder: sideImage('assets/icons/blue_logo.png'),
              subtitleBuilder: (context, action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    action == AuthAction.signIn
                        ? 'Welcome to $APP_NAME! Please sign in to continue.'
                        : 'Welcome to $APP_NAME! Please create an account to continue',
                  ),
                );
              },
              footerBuilder: (context, action) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      action == AuthAction.signIn
                          ? 'By signing in, you agree to our terms and conditions.'
                          : 'By registering, you agree to our terms and conditions.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          },
          '/verify-email': (context) {
            return EmailVerificationScreen(
              headerBuilder: headerIcon(Icons.verified),
              sideBuilder: sideIcon(Icons.verified),
              actionCodeSettings: actionCodeSettings,
              actions: [
                EmailVerifiedAction(() {
                  Navigator.pushReplacementNamed(context, '/home');
                }),
                AuthCancelledAction((context) {
                  FirebaseUIAuth.signOut(context: context);
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
            );
          },
          '/phone': (context) {
            return PhoneInputScreen(
              actions: [
                SMSCodeRequestedAction((context, action, flowKey, phone) {
                  Navigator.of(context).pushReplacementNamed(
                    '/sms',
                    arguments: {
                      'action': action,
                      'flowKey': flowKey,
                      'phone': phone,
                    },
                  );
                }),
              ],
              headerBuilder: headerIcon(Icons.phone),
              sideBuilder: sideIcon(Icons.phone),
            );
          },
          '/sms': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;

            return SMSCodeInputScreen(
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.of(context).pushReplacementNamed('/home');
                })
              ],
              flowKey: arguments?['flowKey'],
              action: arguments?['action'],
              headerBuilder: headerIcon(Icons.sms_outlined),
              sideBuilder: sideIcon(Icons.sms_outlined),
            );
          },
          '/forgot-password': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;

            return ForgotPasswordScreen(
              email: arguments?['email'],
              headerMaxExtent: 200,
              headerBuilder: headerIcon(Icons.lock),
              sideBuilder: sideIcon(Icons.lock),
            );
          },
          // '/email-link-sign-in': (context) {
          //   return EmailLinkSignInScreen(
          //     actions: [
          //       AuthStateChangeAction<SignedIn>((context, state) {
          //         Navigator.pushReplacementNamed(context, '/');
          //       }),
          //     ],
          //     provider: emailLinkProviderConfig,
          //     headerMaxExtent: 200,
          //     headerBuilder: headerIcon(Icons.link),
          //     sideBuilder: sideIcon(Icons.link),
          //   );
          // },
          '/profile': (context) {
            return ProfileScreen(
              actions: [
                SignedOutAction((context) {
                  Navigator.pushReplacementNamed(context, '/');
                }),
                // mfaAction,
              ],
              actionCodeSettings: actionCodeSettings,
              appBar: AppBar(
                title: const Text('Profile'),
              ),
            );
          },
          '/home': (context) {
            return const HomeView();
          },
        },
        title: APP_NAME,
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: [
          FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FirebaseUILocalizations.delegate,
        ],
      ),
    );
  }
}

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  @override
  String get emailInputLabel => 'Enter your email';
}
