import 'package:chat_bot/provider/msg_provider.dart';
import 'package:chat_bot/screen/splash_screen.dart';
import 'package:chat_bot/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MessageProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatBot AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          background: AppColors.background,
          surface: AppColors.surface,
        ),
        fontFamily: 'fontMain',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'fontMain'),
          bodyMedium: TextStyle(fontFamily: 'fontMain'),
          bodySmall: TextStyle(fontFamily: 'fontMain'),
          headlineLarge: TextStyle(fontFamily: 'fontMain'),
          headlineMedium: TextStyle(fontFamily: 'fontMain'),
          headlineSmall: TextStyle(fontFamily: 'fontMain'),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
