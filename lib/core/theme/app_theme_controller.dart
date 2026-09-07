import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme_mode.dart';

final appThemeProvider = NotifierProvider<AppThemeController, AppThemeMode>(() {
  return AppThemeController();
});

class AppThemeController extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    return AppThemeMode.normal;
  }

  void setTheme(AppThemeMode mode) {
    state = AppThemeMode.normal;
  }
}
