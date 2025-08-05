import 'package:firebase_core/firebase_core.dart';
import 'package:fitsyncgemini/firebase_options.dart';
import 'package:fitsyncgemini/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase using the auto-generated options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: FitSyncApp()));
}

class FitSyncApp extends ConsumerWidget {
  const FitSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Get the GoRouter instance from the provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'FitSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
