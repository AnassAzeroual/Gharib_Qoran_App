import 'package:flutter/material.dart';

import '../theme.dart';

/// App-wide toggle that switches displayed numerals between Western (123) and
/// Arabic-Indic (١٢٣). The badge previews the format the NEXT tap will enable,
/// so it is always discoverable regardless of the current state. Rendered for
/// dark chrome (AppBars / header gradients / the viewer bottom bar), so it uses
/// white-on-translucent-white styling.
class NumeralToggleButton extends StatelessWidget {
  const NumeralToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, current, _) {
        final next = current == NumeralSystem.arabicIndic
            ? NumeralSystem.western
            : NumeralSystem.arabicIndic;
        final preview = next == NumeralSystem.arabicIndic ? '١٢٣' : '123';
        return Tooltip(
          message: next == NumeralSystem.arabicIndic
              ? 'الأرقام العربية ١٢٣'
              : 'الأرقام الإنجليزية 123',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => numeralNotifier.value = next,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                preview,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}