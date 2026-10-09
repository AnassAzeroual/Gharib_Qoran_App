import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/palette_store.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';

/// Settings page: every customizable app color with its Arabic label and a
/// description of where it is used. Tapping a row opens an editor (preset
/// swatches + RGB sliders + hex code); changes apply instantly across the
/// whole app and persist in local storage. The reset button restores the
/// factory defaults.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key });

  /// Section titles in display order, derived from the palette entries so
  /// adding a color never requires touching this screen.
  static List<String> _sectionTitles() {
    final titles = <String>[];
    for (final entry in kPaletteEntries) {
      if (!titles.contains(entry.section)) titles.add(entry.section);
    }
    return titles;
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'استعادة الألوان الافتراضية؟',
          style: TextStyle(fontFamily: 'Amiri'),
        ),
        content: const Text(
          'سيتم تجاهل كل الألوان التي اخترتها والرجوع لألوان التطبيق الأصلية.',
          style: TextStyle(fontFamily: 'Amiri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await resetPalette();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة الألوان الافتراضية'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openEditor(BuildContext context, PaletteEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ColorEditor(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => ValueListenableBuilder<AppPalette>(
        valueListenable: paletteNotifier,
        builder: (context, palette, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: palette.settingsHeader,
            foregroundColor: Colors.white,
            title: const Text(
              'إعدادات الألوان',
              style: TextStyle(fontFamily: 'Amiri'),
            ),
            actions: [
              IconButton(
                tooltip: 'استعادة الافتراضي',
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: () => _confirmReset(context),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: NumeralToggleButton(),
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: _sectionTitles().length,
            itemBuilder: (context, index) {
              final title = _sectionTitles()[index];
              final entries = kPaletteEntries
                  .where((e) => e.section == title)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  for (final entry in entries)
                    _ColorRow(
                      entry: entry,
                      current: palette.valueOf(entry.key),
                      onTap: () => _openEditor(context, entry),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final PaletteEntry entry;
  final Color current;
  final VoidCallback onTap;

  const _ColorRow({
    required this.entry,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool customized = current.toARGB32() != entry.fallback.toARGB32();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: current,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              entry.label,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (customized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'مخصص',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.usage,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet color editor: preset swatches, RGB sliders, and a hex field.
/// Every change applies instantly to the whole app and persists.
class _ColorEditor extends StatefulWidget {
  final PaletteEntry entry;

  const _ColorEditor({required this.entry});

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
  static const List<Color> _swatches = [
    Color(0xFF0F766E),
    Color(0xFF134E4A),
    Color(0xFF2DD4BF),
    Color(0xFFFCD34D),
    Color(0xFFE6A15C),
    Color(0xFFC89B27),
    Color(0xFF2FA885),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF1E293B),
    Color(0xFF101418),
    Color(0xFFFFFFFF),
  ];

  late Color _color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _color = paletteNotifier.value.valueOf(widget.entry.key);
    _hexController = TextEditingController(text: _toHex(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  static String _toHex(Color c) {
    final argb = c.toARGB32();
    if ((argb & 0xFF000000) == 0xFF000000) {
      return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color? _parseHex(String text) {
    var hex = text.trim().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  Future<void> _apply(Color c) async {
    setState(() {
      _color = c;
      _hexController.text = _toHex(c);
    });
    await updatePalette(paletteNotifier.value.withValue(widget.entry.key, c));
  }

  Widget _channelSlider({
    required String label,
    required int value,
    required Color active,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: active,
            label: displayNumber(value),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            displayNumber(value),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = (_color.r * 255).round();
    final g = (_color.g * 255).round();
    final b = (_color.b * 255).round();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.entry.label,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.entry.usage,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final swatch in _swatches)
                  GestureDetector(
                    onTap: () => _apply(swatch),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color.toARGB32() == swatch.toARGB32()
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width:
                              _color.toARGB32() == swatch.toARGB32() ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _channelSlider(
              label: 'R',
              value: r,
              active: Colors.red,
              onChanged: (v) => _apply(_color.withValues(red: v / 255)),
            ),
            _channelSlider(
              label: 'G',
              value: g,
              active: Colors.green,
              onChanged: (v) => _apply(_color.withValues(green: v / 255)),
            ),
            _channelSlider(
              label: 'B',
              value: b,
              active: Colors.blue,
              onChanged: (v) => _apply(_color.withValues(blue: v / 255)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hexController,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              ],
              decoration: InputDecoration(
                labelText: 'كود اللون (HEX)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (text) {
                final parsed = _parseHex(text);
                if (parsed != null) {
                  _apply(parsed);
                } else {
                  setState(() => _hexController.text = _toHex(_color));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('كود اللون غير صالح'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }
}
