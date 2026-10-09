import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/models/hizb_menu.dart';
import 'package:quran_app/services/progress_store.dart';

ThumunEntry _thumun(int global, int inHizb) => ThumunEntry(
  thumun: global,
  thumunInHizb: inHizb,
  entryCount: 1,
  firstPage: 1,
  pages: const [1],
);

void main() {
  test('toggle adds then removes a thumun', () async {
    ProgressStore.completedNotifier.value = const {};
    expect(await ProgressStore.toggle(5), isTrue);
    expect(ProgressStore.isCompleted(5), isTrue);
    expect(await ProgressStore.toggle(5), isFalse);
    expect(ProgressStore.isCompleted(5), isFalse);
    ProgressStore.completedNotifier.value = const {};
  });

  test('hizb completes only when all its thumuns are done', () async {
    ProgressStore.completedNotifier.value = const {};
    final hizb = HizbEntry(
      hizb: 1,
      firstPage: 1,
      thumunCount: 8,
      thumuns: [_thumun(1, 1), _thumun(2, 2)],
    );
    expect(
      ProgressStore.hizbCompleted(hizb, ProgressStore.completedNotifier.value),
      isFalse,
    );
    await ProgressStore.toggle(1);
    expect(
      ProgressStore.hizbCompleted(hizb, ProgressStore.completedNotifier.value),
      isFalse,
    );
    await ProgressStore.toggle(2);
    expect(
      ProgressStore.hizbCompleted(hizb, ProgressStore.completedNotifier.value),
      isTrue,
    );
    // setAll(false) clears the whole hizb at once.
    await ProgressStore.setAll([1, 2], false);
    expect(
      ProgressStore.hizbCompleted(hizb, ProgressStore.completedNotifier.value),
      isFalse,
    );
    ProgressStore.completedNotifier.value = const {};
  });

  test('surah completes only when all its thumuns are done', () {
    expect(ProgressStore.surahCompleted(const {}, const {1}), isFalse);
    expect(
      ProgressStore.surahCompleted(const {10, 11}, const {10}),
      isFalse,
    );
    expect(
      ProgressStore.surahCompleted(const {10, 11}, const {10, 11, 12}),
      isTrue,
    );
  });
}
