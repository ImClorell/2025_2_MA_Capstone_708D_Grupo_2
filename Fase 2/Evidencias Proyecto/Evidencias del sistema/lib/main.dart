import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/auth/login_page.dart';
import 'pages/home/inicio_page.dart';
import 'pages/nota/notas_page.dart';
import 'pages/recordatorio/recordatorios_page.dart';
import 'pages/rutina/rutinas_page.dart';
import 'pages/settings_page.dart';
import 'services/notification_service.dart';
import 'services/push_notifications_service.dart';
import 'core/supabase_client.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supa.init(); // Inicializa Supabase
  await PushNotificationsService.init();
  runApp(const AgendAIApp());
}

class AgendAIApp extends StatefulWidget {
  const AgendAIApp({super.key});

  @override
  State<AgendAIApp> createState() => _AgendAIAppState();
}

class _AgendAIAppState extends State<AgendAIApp> {
  // Paleta principal
  static const Color accentColor = Color(0xFF8C3C37); // vino
  static const Color secondaryColor = Color(0xFFF4C7B5); // beige rosado

  // Alternar tema claro/oscuro
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    // Tema claro
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF8F6), // beige claro
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey.shade100,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      ),
    );

    // Tema oscuro
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1C1413), // marrón oscuro elegante
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        surface: Color(0xFF2A1E1C),
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey.shade900,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      ),
    );

    return MaterialApp(
      title: 'AgendAI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthGate(
        isDarkMode: isDarkMode,
        onToggleTheme: () => setState(() => isDarkMode = !isDarkMode),
      ),
    );
  }
}

/// AuthGate que usa Supabase y respeta tu diseño y toggle de tema
class AuthGate extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final client = Supa.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // No hay sesión → mostramos LoginPage con toggle de tema
        if (session == null) {
          return LoginPageWrapper(
            isDarkMode: isDarkMode,
            onToggleTheme: onToggleTheme,
          );
        }

        // Hay sesión → vamos al HomeScreen con bottom bar
        return HomeScreen(
          isDarkMode: isDarkMode,
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}

class LoginPageWrapper extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const LoginPageWrapper({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      isDarkMode: isDarkMode,
      onToggleTheme: onToggleTheme,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const InicioPage(),        // pestaña 0: Inicio (Resumen Diario)
      const NotasPage(),
      const RecordatoriosPage(),
      const RutinasPage(),
      SettingsPage(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notas'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Recordatorios'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Rutinas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
