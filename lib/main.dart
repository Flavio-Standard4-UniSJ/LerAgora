import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leragora/screens/welcome_screen.dart';
import 'package:leragora/screens/home_screen.dart';
import 'package:leragora/screens/login_screen.dart';
import 'package:leragora/screens/signup_screen.dart';
import 'package:leragora/screens/settings_screen.dart';
import 'package:leragora/screens/reader_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkTheme') ?? false;

  runApp(MyApp(isDarkMode: isDark));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDarkTheme;

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.isDarkMode;
  }

  void toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', value);
    setState(() {
      isDarkTheme = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LerAgora',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => WelcomeScreen(onThemeChanged: toggleTheme),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => HomeScreen(onThemeChanged: toggleTheme),
        '/settings': (_) => SettingsScreen(onThemeChanged: toggleTheme),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/reader') {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (context) =>
                ReaderScreen(bookTitle: args['title'], bookPath: args['path']),
          );
        }
        return null;
      },
    );
  }
}
