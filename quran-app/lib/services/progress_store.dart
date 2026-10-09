import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hizb_menu.dart';

/// Memorization progress (الحفظ): the set of completed thumuns (global
/// 1..480), persisted in local storage. This ONE set is the single source of
/// truth for both menus, so they always stay in sync:
/// - a thumun counts as completed when its key is in the set;
/// - a hizb counts as completed when all its thumuns are;
/// - a surah counts as completed when every thumun containing its glossary
///   words is completed (see DataService.thumunsOfSurah).
class ProgressStore {
  ProgressStore._();

  static const String storageKey = 'memorized_thumuns_v1';

  static final ValueNotifier<Set<int>> completedNotifier = ValueNotifier(
    const {},
  );

  static bool isCompleted(int thumun) =>
      completedNotifier.value.contains(thumun);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      completedNotifier.value = {
        for (final e in decoded)
          if (e is int && e >= 1 && e <= 480) e,
      };
    } catch (_) {
      // Corrupt storage is ignored — progress simply starts empty.
    }
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode(completedNotifier.value.toList()),
      );
    } catch (_) {
      // Storage failures must never break toggling.
    }
  }

  /// Toggles one thumun. Returns true when it ends up completed.
  static Future<bool> toggle(int thumun) async {
    final current = {...completedNotifier.value};
    final bool completed;
    if (current.contains(thumun)) {
      current.remove(thumun);
      completed = false;
    } else {
      current.add(thumun);
      completed = true;
    }
    completedNotifier.value = current;
    await _save();
    return completed;
  }

  /// Marks every thumun in [thumuns] completed (or clears them all).
  static Future<void> setAll(Iterable<int> thumuns, bool complete) async {
    final current = {...completedNotifier.value};
    if (complete) {
      current.addAll(thumuns);
    } else {
      current.removeAll(thumuns);
    }
    completedNotifier.value = current;
    await _save();
  }

  static bool hizbCompleted(HizbEntry hizb, Set<int> completed) =>
      hizb.thumuns.isNotEmpty &&
      hizb.thumuns.every((t) => completed.contains(t.thumun));

  static bool surahCompleted(Set<int> surahThumuns, Set<int> completed) =>
      surahThumuns.isNotEmpty && surahThumuns.every(completed.contains);
}
