import 'package:fitsyncgemini/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/constants/app_theme.dart';
import 'package:fitsyncgemini/config/supabase_config.dart';
import 'package:fitsyncgemini/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize services
  await _initializeServices();

  runApp(const ProviderScope(child: FitSyncApp()));
}

Future<void> _initializeServices() async {
  try {
    // Initialize notification service
    await NotificationService.initialize();
    print('✅ Services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
  }
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
      themeMode: ThemeMode.dark, // Default to dark theme for futuristic look
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(
              1.0,
            ), // Prevent text scaling issues
          ),
          child: child!,
        );
      },
    );
  }
}
