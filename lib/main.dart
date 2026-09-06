import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme_controller.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DocumentScreeningApp(),
    ),
  );
}

class DocumentScreeningApp extends ConsumerWidget {
  const DocumentScreeningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'AI Document Screening',
      theme: themeMode.themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
