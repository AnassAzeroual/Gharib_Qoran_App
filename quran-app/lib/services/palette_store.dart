import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Loads/saves the custom color palette in local storage (SharedPreferences).
/// Only non-default colors are stored; missing keys fall back to defaults,
/// so the app always starts with a complete palette.
class PaletteStore {
  PaletteStore._();

  static const String key = 'custom_palette_v1';

  static Future<void> loadInto(ValueNotifier<AppPalette> notifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return;
      notifier.value =
          AppPalette.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt storage is ignored — the app keeps working with defaults.
    }
  }

  static Future<void> save(AppPalette palette) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(palette.toJson()));
    } catch (_) {
      // Storage failures must never break color editing.
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Best effort only.
    }
  }
}

/// Assigns a new palette (applies it live) and persists it.
/// Any manual edit marks the active preset as 'custom'.
Future<void> updatePalette(AppPalette palette) async {
  paletteNotifier.value = palette;
  activePresetIdNotifier.value = 'custom';
  await PaletteStore.save(palette);
}

/// Applies a curated preset by id (applies live) and persists it.
Future<void> applyPreset(String id) async {
  final preset = kPalettePresets.firstWhere(
    (p) => p.id == id,
    orElse: () => kPalettePresets.first,
  );
  paletteNotifier.value = preset.build();
  activePresetIdNotifier.value = preset.id;
  await PaletteStore.save(paletteNotifier.value);
}

/// Restores the factory defaults (applies live) and clears stored colors.
Future<void> resetPalette() async {
  paletteNotifier.value = AppPalette.defaults();
  await PaletteStore.clear();
}
