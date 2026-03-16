import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/dashboard.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
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
  runApp(const ProviderScope(child: AstroPanditApp()));
}

class AstroPanditApp extends StatelessWidget {
  const AstroPanditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroPandit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/otp': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
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
  }
}
