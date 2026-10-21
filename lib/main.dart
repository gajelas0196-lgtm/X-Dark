import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'landing_page.dart'; 
import 'login_page.dart';
import 'loader_page.dart';      
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'splash.dart'; 
import 'music_page.dart'
import 'chat_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  String initialRoute = '/'; 
  runApp(MyApp(startRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'X•Dark V1.0',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Rajdhani',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFF00D4AA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: startRoute, 
      
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
  case '/chat':
    final sessionKey = args?['sessionKey'] ?? 'default_session_123';
    return MaterialPageRoute(
      builder: (_) => ChatPage(sessionKey: sessionKey),
    );

  case '/login':
    return MaterialPageRoute(builder: (_) => const LoginPage());

  case '/splash':
    return MaterialPageRoute(
      builder: (_) => SplashPage(data: args ?? {}),
    );

  case '/buy_account':
    return MaterialPageRoute(builder: (_) => const BuyAccountPage());
    
  // ... sisa case lainnya ...
}

          case '/loader':
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args?['username'] ?? '',
                password: args?['password'] ?? '',
                role: args?['role'] ?? 'member',
                sessionKey: args?['key'] ?? '',
                expiredDate: args?['expiredDate'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args?['listBug'] ?? []),
                listPayload: List<Map<String, dynamic>>.from(args?['listPayload'] ?? []),
                listDDoS: List<Map<String, dynamic>>.from(args?['listDDoS'] ?? []),
                news: List<Map<String, dynamic>>.from(args?['news'] ?? []),
              ),
            );

          case '/attack':
            return MaterialPageRoute(
              builder: (_) => AttackPage(
                username: args?['username'] ?? '',
                password: args?['password'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args?['listBug'] ?? []),
                role: args?['role'] ?? '',
                expiredDate: args?['expiredDate'] ?? '',
                sessionKey: args?['sessionKey'] ?? '',
              ),
            );

          case '/seller':
            return MaterialPageRoute(
              builder: (_) => SellerPage(keyToken: args?['keyToken'] ?? ''),
            );

          case '/admin':
            return MaterialPageRoute(
              builder: (_) => AdminPage(sessionKey: args?['sessionKey'] ?? ''),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("404 - PANEL NOT FOUND", style: TextStyle(color: Colors.red))),
              ),
            );
        }
      },
    );
  }
}