import 'package:flutter/material.dart';
import 'package:push_notification_manager/push_notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/signup.dart';
import '../screens/welcome_pages.dart';
import '../screens/navigation.dart';
import '../screens/change_password_screen.dart';
import '../screens/username_screen.dart';
import 'config.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey:
        supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  PushNotificationManager().initFirebaseAndLocalNotifications();
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFEDD33)),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _dots = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          if (_dots.length == 3) {
            _dots = '';
          } else {
            _dots = '$_dots.';
          }
        });
      }
    });
    supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final event = data.event;
      final user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        final profile = await supabase
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();

        if (!mounted) return;

        if (profile['username'] == null ||
            (profile['username'] as String).isEmpty) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  UsernameScreen(userId: user.id, email: user.email ?? ''),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Navigation(isGuest: false)),
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          (route) => false,
        );
      }
    });

    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      supabase.auth.getSessionFromUrl(uri);
    });

    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', session.user.id)
          .single();

      if (!mounted) return;

      if (profile['username'] == null ||
          (profile['username'] as String).isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UsernameScreen(
              userId: session.user.id,
              email: session.user.email ?? '',
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Navigation(isGuest: false)),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenWelcome = prefs.getBool('seenWelcome') ?? false;

    if (!mounted) return;

    if (seenWelcome) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const SignupPage()));
    } else {
      await prefs.setBool('seenWelcome', true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomePages()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEDD33),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/next_chapter_logo.png', height: 80),
            const SizedBox(height: 16),
            Text(
              'Loading$_dots',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
