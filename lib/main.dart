import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pg_application/screens/main_page_admin.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
// import 'package:pg_application/screens/addnewpg_screen.dart';
// import 'package:pg_application/screens/admin_screen.dart';
// import 'package:pg_application/screens/home_screen.dart';
import 'package:pg_application/screens/main_page.dart';
import 'package:pg_application/screens/login_screen.dart';
import 'package:pg_application/screens/splash_screen.dart';
// import 'package:pg_application/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode('en');
  await Supabase.initialize(
    url: 'https://geyczidzskcbjwukjthf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdleWN6aWR6c2tjYmp3dWtqdGhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwMzUwMjQsImV4cCI6MjA3MTYxMTAyNH0.y8tJKN_woRn_RoWZTOaly-mCzM3ORr6jWLCw6yMEnvc',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application. hehe by Neeeeell
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PG Application',
      theme: ThemeData.light(
        useMaterial3: true,
      ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      // Using splash screen as entry point
      home: const SplashScreen(),
    );
  }
}

// class CheckAccountLogin extends StatelessWidget {
//   const CheckAccountLogin({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         // If user is logged in (snapshot has data), go to homepage
//         if (!snapshot.hasData) {
//           return const Login();
//         }
//         if (snapshot.data!.uid == '8grHNpbvJnUaOoACbtAs9HXJ5zx1') {
//           return const MainPageAdmin();
//         }
//         return const MainPage();
//       },
//     );
//   }
// }
