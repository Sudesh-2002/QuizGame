import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register test device BEFORE initializing ads
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['A40C6412ABF0CDE884C40F52E0D8D7D3'],
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService().initialize();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(autoNavigate: false),
      error: (_, __) => const LoginScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userModelProvider.notifier).state = null;
          });
          return const LoginScreen();
        }
        return _UserLoader(uid: firebaseUser.uid);
      },
    );
  }
}

class _UserLoader extends ConsumerWidget {
  final String uid;
  const _UserLoader({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider(uid));

    return userAsync.when(
      loading: () => const SplashScreen(autoNavigate: false),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userModelProvider.notifier).state = user;
        });
        return const HomeScreen();
      },
    );
  }
}