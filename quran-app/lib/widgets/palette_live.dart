import 'package:flutter/material.dart';

import '../theme.dart';

/// Rebuilds [child] on every palette change. Route content must subscribe
/// directly: ancestor rebuilds from main.dart stop at Navigator route
/// entries, so screens wrapped in this repaint live — even while covered by
/// another route — and are fresh when navigated back to.
class PaletteLive extends StatelessWidget {
  final Widget child;

  const PaletteLive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: paletteNotifier,
      builder: (context, _, _) => child,
    );
  }
}
