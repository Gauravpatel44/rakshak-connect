import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants/app_routes.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/contacts/contacts_screen.dart';
import 'screens/contacts/add_edit_contact_screen.dart';
import 'screens/emergency_call/emergency_call_screen.dart';
import 'screens/government/government_services_screen.dart';
import 'screens/history/alert_history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/location/live_location_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/sos/sos_alert_screen.dart';
import 'providers/medical_profile_provider.dart';
import 'providers/locale_provider.dart';
import 'localization/app_localizations.dart';
import 'screens/language/language_select_screen.dart';
import 'screens/medical_id/medical_id_screen.dart';
import 'screens/medical_id/edit_medical_id_screen.dart';
import 'screens/siren/siren_screen.dart';
import 'screens/fake_call/fake_call_setup_screen.dart';
import 'screens/fake_call/fake_incoming_call_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/tips/emergency_tips_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

/// Entry point: initializes Firebase and starts the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Performance: prefer high-refresh-rate display ──────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // BUG-13 fix: Only lock statusBarColor to transparent. Remove the hardcoded
  // statusBarIconBrightness — Material 3 (useMaterial3: true) automatically
  // sets the correct icon brightness (dark/light) based on the active theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  bool firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().initialize();
    await WidgetService().initialize();
    firebaseReady = true;
  } catch (e) {
    debugPrint('⚠️  Firebase not configured: $e');
  }

  runApp(RakshakConnectApp(firebaseReady: firebaseReady));
}

/// Root app widget — MultiProvider wraps the entire tree once.
/// Uses Selector at the MaterialApp level so theme changes don't
/// rebuild all providers from scratch.
class RakshakConnectApp extends StatelessWidget {
  final bool firebaseReady;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const RakshakConnectApp({super.key, this.firebaseReady = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (_, themeProvider, localeProvider, child) {
          return MaterialApp(
            navigatorKey: RakshakConnectApp.navigatorKey,
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLanguages
                .map((l) => Locale(l.code)),
            // Bug #24 fix: global messenger key for foreground FCM notifications
            scaffoldMessengerKey: NotificationService.messengerKey,

            // ── Named Routes ─────────────────────────────
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => firebaseReady
                  ? const SplashScreen()
                  : const _FirebaseSetupScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              // Bug #23 fix: contacts route now points to ContactsScreen
              AppRoutes.contacts: (_) => const ContactsScreen(),
              AppRoutes.addEditContact: (_) => const AddEditContactScreen(),
              AppRoutes.sosAlert: (_) => const SosAlertScreen(),
              AppRoutes.liveLocation: (_) => const LiveLocationScreen(),
              AppRoutes.governmentServices: (_) =>
                  const GovernmentServicesScreen(),
              AppRoutes.emergencyCall: (_) => const EmergencyCallScreen(),
              AppRoutes.alertHistory: (_) => const AlertHistoryScreen(),
              AppRoutes.profile: (_) => const ProfileScreen(),
              AppRoutes.editProfile: (_) => const EditProfileScreen(),
              AppRoutes.settings: (_) => const SettingsScreen(),
              AppRoutes.emergencyTips: (_) => const EmergencyTipsScreen(),
              AppRoutes.siren: (_) => const SirenScreen(),
              AppRoutes.fakeCallSetup: (_) => const FakeCallSetupScreen(),
              AppRoutes.fakeCallIncoming: (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments
                    as Map<String, dynamic>?;
                return FakeIncomingCallScreen(
                  callerName: args?['name'] ?? 'Mom ❤️',
                  callerNumber: args?['phone'] ?? '+91 98765 43210',
                );
              },
              AppRoutes.medicalId: (_) => const MedicalIdScreen(),
              AppRoutes.editMedicalId: (_) => const EditMedicalIdScreen(),
              AppRoutes.language: (_) => const LanguageSelectScreen(),
            },
          );
        },
      ),
    );
  }
}

// ── Firebase Setup Screen ─────────────────────────────────────────────

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD32F2F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(Icons.shield_rounded, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Rakshak Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            color: Color(0xFFD32F2F), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Firebase Setup Required',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    for (final step in const [
                      '1️⃣  Go to console.firebase.google.com',
                      '2️⃣  Create project → Add Android app',
                      '      Package: com.gaurav.rakshak_connect',
                      '3️⃣  Download google-services.json',
                      '4️⃣  Place it in: android/app/',
                      '5️⃣  Enable Email/Password Auth',
                      '6️⃣  Create Firestore Database',
                      '7️⃣  Update firebase_options.dart',
                      '8️⃣  Hot restart the app ✅',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(step,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF424242),
                                height: 1.4)),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'UI is fully built & ready!\nConnect Firebase to unlock all features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
