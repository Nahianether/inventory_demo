import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings/currency.dart';

/// Settings State
class SettingsState {
  final Currency currency;

  const SettingsState({
    required this.currency,
  });

  SettingsState copyWith({
    Currency? currency,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
    );
  }
}

/// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(const SettingsState(currency: Currencies.bdt)) {
    _loadSettings();
  }

  static const String _currencyKey = 'selected_currency';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_currencyKey) ?? 'BDT';
      state = state.copyWith(currency: Currencies.fromCode(currencyCode));
    } catch (e) {
      // If loading fails, keep default BDT
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
      state = state.copyWith(currency: currency);
    } catch (e) {
      // Handle error
    }
  }
}

/// Settings Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

/// Currency Provider (shortcut)
final currencyProvider = Provider<Currency>((ref) {
  return ref.watch(settingsProvider).currency;
});
