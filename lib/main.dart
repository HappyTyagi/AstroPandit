import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/dashboard.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/app_preferences.dart';
import 'services/api_client.dart';
import 'services/push_token_sync_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('[Pandit] .env load skipped: $error');
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await ApiClient().loadToken();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushTokenSyncService.initialize();
  } catch (e) {
    debugPrint('[Pandit] Firebase init failed: $e');
  }
  await AppPreferences.init();
  runApp(const ProviderScope(child: AstroPanditApp()));
}

class AstroPanditApp extends StatelessWidget {
  const AstroPanditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppPreferences.themeModeNotifier,
      builder: (BuildContext context, ThemeMode themeMode, Widget? _) {
        return MaterialApp(
          title: 'AstroPandit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final width = mediaQuery.size.width;
            final isTablet = width >= 600;
            final maxWidth = isTablet ? 900.0 : width;
            return MediaQuery(
              data: mediaQuery,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/login': (context) => LoginScreen(),
            '/otp': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
              return OtpScreen(
                mobileNo: args?['mobileNo'] ?? '',
                sessionId: args?['sessionId'] ?? '',
              );
            },
            '/dashboard': (context) => Dashboard(),
            '/profile-setup': (context) => Dashboard(), // Placeholder
          },
        );
      },
    );
  }
}
