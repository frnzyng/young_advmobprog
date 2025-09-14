import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:young_advmobprog/firebase_options.dart';
import 'package:young_advmobprog/providers/theme_provider.dart';
import 'package:young_advmobprog/screens/change_password_screen.dart';
import 'package:young_advmobprog/screens/change_username_screen.dart';
import 'package:young_advmobprog/screens/delete_account_screen.dart';
import 'package:young_advmobprog/screens/firebase_register_screen.dart';
import 'package:young_advmobprog/screens/home_screen.dart';
import 'package:young_advmobprog/screens/login_screen.dart';
import 'package:young_advmobprog/screens/profile_screen.dart';
import 'package:young_advmobprog/screens/register_screen.dart';
import 'package:young_advmobprog/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    await dotenv.load(fileName: 'assets/.env'); 
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MainApp());
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'Blog App',
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/firebaseRegister': (context) => const FirebaseRegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/changeUsername': (context) => const ChangeUsernameScreen(),
              '/changePassword': (context) => const ChangePasswordScreen(),
              '/deleteAccount': (context) => const DeleteAccountScreen(),
            },
          );
        },
      ),
    );
  }
}
