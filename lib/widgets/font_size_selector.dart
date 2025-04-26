import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme.dart';
import '../utils/quill_extensions.dart';

class FontSizeSelector extends StatefulWidget {
  final quill.QuillController controller;

  const FontSizeSelector({
    Key? key, 
    required this.controller,
  }) : super(key: key);

  @override
  State<FontSizeSelector> createState() => _FontSizeSelectorState();
}

class _FontSizeSelectorState extends State<FontSizeSelector> {
  // Default font sizes in points
  final List<double> fontSizes = [8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 60, 72];
  double _selectedSize = 16.0; // Default size

  @override
  void initState() {
    super.initState();
    // Try to determine the current font size
    _getCurrentFontSize();
  }

  void _getCurrentFontSize() {
    final size = widget.controller.getCurrentFontSize();
    if (size != null && fontSizes.contains(size)) {
      setState(() {
        _selectedSize = size;
      });
    }
  }

  void _applyFontSize(double size) {
    // Use the extension method to apply font size
    widget.controller.applyFontSize(size);
    
    setState(() {
      _selectedSize = size;
    });
  }

  // Show a menu with common font sizes
  void _showFontSizeMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<double>(
      context: context,
      position: position,
      items: fontSizes.map((size) {
        return PopupMenuItem<double>(
          value: size,
          child: Text(
            '$size pt',
            style: TextStyle(
              fontWeight: _selectedSize == size ? FontWeight.bold : FontWeight.normal,
              color: _selectedSize == size ? AppTheme.primaryColor : null,
            ),
          ),
        );
      }).toList(),
    ).then((size) {
      if (size != null) {
        _applyFontSize(size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: 'Font Size',
        child: InkWell(
          onTap: _showFontSizeMenu,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.format_size, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_selectedSize.toInt()}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}