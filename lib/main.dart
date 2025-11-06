import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/home/viewmodel.dart';
import 'ui/home/home.dart';
import 'ui/login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SongViewModel()),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music App',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// -------------------------------
/// Xử lý đăng nhập / đăng xuất
/// -------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 Nếu đã đăng nhập → về MusicHomePage
        if (snapshot.hasData) {
          return const HomePage();
        }
        // 🔹 Nếu chưa đăng nhập → về LoginScreen
        return LoginScreen();
      },
    );
  }
}
