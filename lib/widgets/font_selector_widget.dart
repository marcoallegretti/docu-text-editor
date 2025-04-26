import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme.dart';

class FontSelectorWidget extends StatefulWidget {
  final quill.QuillController controller;
  final Function(String) onFontSelected;

  const FontSelectorWidget({
    Key? key,
    required this.controller,
    required this.onFontSelected,
  }) : super(key: key);

  @override
  State<FontSelectorWidget> createState() => _FontSelectorWidgetState();
}

class _FontSelectorWidgetState extends State<FontSelectorWidget> {
  String _selectedFont = 'Poppins';
  bool _showFontSelector = false;

  // List of available fonts
  final List<Map<String, dynamic>> _availableFonts = [
    {'name': 'Poppins', 'font': GoogleFonts.poppins()},
    {'name': 'Roboto', 'font': GoogleFonts.roboto()},
    {'name': 'Lato', 'font': GoogleFonts.lato()},
    {'name': 'Open Sans', 'font': GoogleFonts.openSans()},
    {'name': 'Montserrat', 'font': GoogleFonts.montserrat()},
    {'name': 'Nunito', 'font': GoogleFonts.nunito()},
    {'name': 'Raleway', 'font': GoogleFonts.raleway()},
    {'name': 'Ubuntu', 'font': GoogleFonts.ubuntu()},
    {'name': 'Merriweather', 'font': GoogleFonts.merriweather()},
    {'name': 'Playfair Display', 'font': GoogleFonts.playfairDisplay()},
    {
      'name': 'Source Sans Pro',
      'font': GoogleFonts.sourceSans3()
    }, // Using Source Sans 3 instead
    {'name': 'PT Serif', 'font': GoogleFonts.ptSerif()},
    {'name': 'Oswald', 'font': GoogleFonts.oswald()},
    {'name': 'Lora', 'font': GoogleFonts.lora()},
    {'name': 'Fira Sans', 'font': GoogleFonts.firaSans()},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showFontSelector = !_showFontSelector;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedFont,
                  style: _availableFonts
                      .firstWhere(
                          (font) => font['name'] == _selectedFont)['font']
                      .copyWith(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Icon(
                  _showFontSelector
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_showFontSelector)
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(top: 8),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 250,
                maxWidth: 220,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Select Font',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableFonts.length,
                      itemBuilder: (context, index) {
                        final font = _availableFonts[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            font['name'],
                            style: font['font'].copyWith(fontSize: 14),
                          ),
                          selected: _selectedFont == font['name'],
                          selectedTileColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          onTap: () {
                            setState(() {
                              _selectedFont = font['name'];
                              _showFontSelector = false;
                            });

                            // Apply font to selected text
                            final fontName = font['name'];
                            widget.onFontSelected(fontName);

                            // Show a brief confirmation toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Font changed to $fontName'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
