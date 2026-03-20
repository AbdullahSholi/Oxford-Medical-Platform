import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _key = 'app_locale';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_loadSaved(_prefs));

  static Locale _loadSaved(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    return Locale(code ?? 'en');
  }

  void setLocale(Locale locale) {
    _prefs.setString(_key, locale.languageCode);
    emit(locale);
  }

  void toggleLocale() {
    final next = state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    setLocale(next);
  }
}
