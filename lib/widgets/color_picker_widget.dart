import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme.dart';
import '../utils/quill_defaults.dart';

class AdvancedColorPickerWidget extends StatefulWidget {
  final quill.QuillController controller;
  final bool isBackground;

  const AdvancedColorPickerWidget({
    Key? key,
    required this.controller,
    required this.isBackground,
  }) : super(key: key);

  @override
  State<AdvancedColorPickerWidget> createState() => _AdvancedColorPickerWidgetState();
}

class _AdvancedColorPickerWidgetState extends State<AdvancedColorPickerWidget> {
  Color _selectedColor = Colors.black;
  
  // Preset colors for text and highlighting
  late final List<Color> _textColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.teal,
    AppTheme.primaryColor,
    AppTheme.accentColor,
    AppTheme.errorColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.linkColor,
  ];
  
  late final List<Color> _highlightColors = [
    Colors.yellow.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
    Colors.teal.shade100,
    Colors.pink.shade100,
    Colors.lime.shade100,
    AppTheme.focusColor,
    AppTheme.primaryColor.withOpacity(0.15),
    AppTheme.accentColor.withOpacity(0.15),
  ];

  List<Color> get colorOptions => widget.isBackground ? _highlightColors : _textColors;

  void _applyColor(Color color) {
    // Use our utility function to apply the color
    if (widget.isBackground) {
      QuillDefaults.applyBackgroundColor(widget.controller, color);
    } else {
      QuillDefaults.applyTextColor(widget.controller, color);
    }
    
    setState(() {
      _selectedColor = color;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set default color based on type
    _selectedColor = widget.isBackground ? _highlightColors.first : _textColors.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode 
        ? (widget.isBackground ? Colors.white.withOpacity(0.7) : Colors.white) 
        : (widget.isBackground ? Colors.black.withOpacity(0.7) : Colors.black);
        
    return IconButton(
      icon: Icon(
        widget.isBackground ? Icons.format_color_fill : Icons.format_color_text,
        color: iconColor,
      ),
      tooltip: widget.isBackground ? 'Highlight Color' : 'Text Color',
      onPressed: () => _showColorPicker(context),
    );
  }

  void _showColorPicker(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final contentWidth = isMobile ? MediaQuery.of(context).size.width * 0.8 : 300.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isBackground ? 'Highlight Color' : 'Text Color'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentWidth,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick color palette
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Colors',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final color in colorOptions)
                            InkWell(
                              onTap: () {
                                _applyColor(color);
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    if (_selectedColor == color)
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: _selectedColor == color
                                    ? const Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Advanced color picker toggle
                TextButton.icon(
                  icon: const Icon(Icons.palette),
                  label: const Text('Advanced Color Options'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAdvancedColorPicker(context);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedColorPicker(BuildContext context) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final wheelDiameter = isMobile ? 200.0 : 165.0;
    
    final Color result = await showColorPickerDialog(
      context,
      _selectedColor,
      title: Text(
        widget.isBackground ? 'Select Highlight Color' : 'Select Text Color',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: wheelDiameter,
      enableShadesSelection: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.wheel: true,
      },
      actionButtons: ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: true,
      ),
      constraints: BoxConstraints(
        minHeight: 480,
        minWidth: isMobile ? MediaQuery.of(context).size.width * 0.8 : 320,
        maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.9 : 400,
      ),
    );

    _applyColor(result);
  }
}