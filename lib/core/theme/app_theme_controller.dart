import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_storage_service.dart';
import 'app_theme_mode.dart';

final appThemeProvider = NotifierProvider<AppThemeController, AppThemeMode>(() {
  return AppThemeController();
});

class AppThemeController extends Notifier<AppThemeMode> {
  late final SecureStorageService _storage;

  @override
  AppThemeMode build() {
    _storage = ref.watch(secureStorageProvider);
    Future.microtask(() => _loadPersistedTheme());
    return AppThemeMode.normal;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final saved = await _storage.getTheme();
      if (saved != null) {
        final mode = AppThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AppThemeMode.normal,
        );
        state = mode;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      await _storage.saveTheme(mode.name);
    } catch (_) {}
  }
}
