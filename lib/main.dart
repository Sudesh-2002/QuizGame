import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
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

// ── AuthGate ───────────────────────────────────────────────────────
// Sits between app start and screens.
// Watches Firebase auth state and routes accordingly.
// On reopen: Firebase restores session → AuthGate loads user
// from Firestore → sets userModelProvider → goes to HomeScreen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // Still checking Firebase auth state
      loading: () => const SplashScreen(autoNavigate: false),

      // Not logged in → go to login
      error: (_, __) => const LoginScreen(),

      data: (firebaseUser) {
        if (firebaseUser == null) {
          // Clear local state on logout
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userModelProvider.notifier).state = null;
          });
          return const LoginScreen();
        }

        // Firebase user exists → load from Firestore
        return _UserLoader(uid: firebaseUser.uid);
      },
    );
  }
}

// ── _UserLoader ────────────────────────────────────────────────────
// Fetches the UserModel from Firestore for the restored session,
// sets it into userModelProvider, then goes to HomeScreen.
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

        // Set into local provider so all screens can read it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userModelProvider.notifier).state = user;
        });

        return const HomeScreen();
      },
    );
  }
}