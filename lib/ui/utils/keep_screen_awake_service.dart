import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@immutable
class KeepScreenAwakeStatus {
  final bool enabled;
  final bool loaded;

  const KeepScreenAwakeStatus({required this.enabled, required this.loaded});
}

class KeepScreenAwakeService {
  static const String _prefsKey = 'host_keep_screen_awake';

  static final ValueNotifier<KeepScreenAwakeStatus> status = ValueNotifier(
    const KeepScreenAwakeStatus(enabled: false, loaded: false),
  );

  static Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKey) ?? false;
    status.value = KeepScreenAwakeStatus(enabled: enabled, loaded: true);
    return enabled;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    status.value = KeepScreenAwakeStatus(enabled: enabled, loaded: true);
    await apply(enabled);
  }

  static Future<void> apply(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } on MissingPluginException {
      // Unit/widget tests (and some unsupported platforms) don't register plugins.
      // Treat as a no-op so tests stay stable.
    } on PlatformException {
      // Some OEMs/targets might deny/ignore. Treat as best-effort.
    } catch (_) {
      // Best-effort: never let this crash the host UI.
    }
  }
}
