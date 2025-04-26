import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart' show Attribute, QuillController;
import 'quill_defaults.dart';

class TextFormatter {
  // Toolbar button definitions
  static List<Widget> getToolbarButtons(quill.QuillController controller) {
    return [
      HistoryButton(controller: controller, undo: true),
      HistoryButton(controller: controller, undo: false),
      SizedBox(width: 0.5, child: Container(color: Colors.grey.shade300, height: 20)),
      
      // Text formatting buttons
      ToggleStyleButton(
        attribute: Attribute.bold,
        controller: controller,
        icon: Icons.format_bold,
      ),
      ToggleStyleButton(
        attribute: Attribute.italic,
        controller: controller,
        icon: Icons.format_italic,
      ),
      ToggleStyleButton(
        attribute: Attribute.underline,
        controller: controller,
        icon: Icons.format_underline,
      ),
      ToggleStyleButton(
        attribute: Attribute.strikeThrough,
        controller: controller,
        icon: Icons.format_strikethrough,
      ),
      SizedBox(width: 0.5, child: Container(color: Colors.grey.shade300, height: 20)),
      
      // Alignment buttons
      SelectAlignmentButton(controller: controller, alignment: Attribute.leftAlignment, icon: Icons.format_align_left),
      SelectAlignmentButton(controller: controller, alignment: Attribute.centerAlignment, icon: Icons.format_align_center),
      SelectAlignmentButton(controller: controller, alignment: Attribute.rightAlignment, icon: Icons.format_align_right),
      SelectAlignmentButton(controller: controller, alignment: Attribute.justifyAlignment, icon: Icons.format_align_justify),
      SizedBox(width: 0.5, child: Container(color: Colors.grey.shade300, height: 20)),
      
      // List buttons
      ToggleStyleButton(
        attribute: Attribute.ul,
        controller: controller,
        icon: Icons.format_list_bulleted,
      ),
      ToggleStyleButton(
        attribute: Attribute.ol,
        controller: controller,
        icon: Icons.format_list_numbered,
      ),
      SizedBox(width: 0.5, child: Container(color: Colors.grey.shade300, height: 20)),
      
      // Font size button
      SelectHeaderStyleButton(controller: controller),
      
      // Color buttons
      ColorButton(controller: controller, isBackground: false),
      ColorButton(controller: controller, isBackground: true),
    ];
  }

  // Helper to create an adaptable responsive toolbar layout for different screen sizes
  static Widget buildResponsiveToolbar(BuildContext context, quill.QuillController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // For smaller screens, use a scrollable toolbar
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: getToolbarButtons(controller),
        ),
      );
    } else {
      // For larger screens, use a fixed toolbar
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: getToolbarButtons(controller),
      );
    }
  }
}

// Custom Quill toolbar button implementations
class HistoryButton extends StatelessWidget {
  final quill.QuillController controller;
  final bool undo;

  const HistoryButton({required this.controller, required this.undo, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(undo ? Icons.undo : Icons.redo),
      tooltip: undo ? 'Undo' : 'Redo',
      onPressed: () {
        if (undo) {
          controller.undo();
        } else {
          controller.redo();
        }
      },
    );
  }
}

class ToggleStyleButton extends StatelessWidget {
  final quill.Attribute attribute;
  final quill.QuillController controller;
  final IconData icon;

  const ToggleStyleButton({
    required this.attribute,
    required this.controller,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a simple StatefulBuilder instead of ValueListenableBuilder
    // to make it simpler and avoid type issues
    return StatefulBuilder(
      builder: (context, setState) {
        // Check if the attribute is already applied to the current selection
        final style = controller.getSelectionStyle();
        final isActive = style.containsKey(attribute.key) && 
                        style.attributes[attribute.key]?.value == attribute.value;
        
        return IconButton(
          icon: Icon(icon),
          color: isActive ? Theme.of(context).primaryColor : null,
          tooltip: attribute.toString(),
          onPressed: () {
            // Toggle the attribute - if it's active, remove it, otherwise add it
            if (isActive) {
              // Special handling for lists
              if (attribute == quill.Attribute.ul || attribute == quill.Attribute.ol) {
                // Remove list formatting by clearing the attribute
                // We'll implement a custom method to handle list removal
                _removeListFormat(controller, attribute);
              } else {
                // For other attributes, just clear formatting
                controller.formatSelection(null);
              }
            } else {
              // Apply the attribute
              controller.formatSelection(attribute);
            }
            // Force update the UI
            setState(() {});
          },
        );
      },
    );
  }
  
  // Helper method to properly remove list formatting
  void _removeListFormat(quill.QuillController controller, quill.Attribute attribute) {
    // We'll use a simpler approach
    if (attribute == quill.Attribute.ul) {
      // For bullet lists
      controller.formatSelection(quill.Attribute.clone(quill.Attribute.ul, null));
    } else if (attribute == quill.Attribute.ol) {
      // For numbered lists
      controller.formatSelection(quill.Attribute.clone(quill.Attribute.ol, null));
    }
  }
}

class SelectAlignmentButton extends StatelessWidget {
  final quill.Attribute alignment;
  final quill.QuillController controller;
  final IconData icon;

  const SelectAlignmentButton({
    required this.controller,
    required this.alignment,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ValueNotifier<bool>(false),
      builder: (context, isActive, _) {
        return IconButton(
          icon: Icon(icon),
          color: isActive ? Theme.of(context).primaryColor : null,
          tooltip: alignment.toString(),
          onPressed: () => controller.formatSelection(alignment),
        );
      },
    );
  }
}

class ColorButton extends StatelessWidget {
  final quill.QuillController controller;
  final bool isBackground;

  const ColorButton({
    required this.controller,
    required this.isBackground,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isBackground ? Icons.format_color_fill : Icons.format_color_text),
      tooltip: isBackground ? 'Background Color' : 'Text Color',
      onPressed: () => _showColorPicker(context),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isBackground ? 'Background Color' : 'Text Color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorButton(context, Colors.black),
                _buildColorButton(context, Colors.red),
                _buildColorButton(context, Colors.green),
                _buildColorButton(context, Colors.blue),
                _buildColorButton(context, Colors.yellow),
                _buildColorButton(context, Colors.orange),
                _buildColorButton(context, Colors.purple),
                _buildColorButton(context, Colors.pink),
                _buildColorButton(context, Colors.teal),
                _buildColorButton(context, Colors.grey),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(BuildContext context, Color color) {
    return InkWell(
      onTap: () {
        // Use our utility class to format and apply color
        if (isBackground) {
          QuillDefaults.applyBackgroundColor(controller, color);
        } else {
          QuillDefaults.applyTextColor(controller, color);
        }
        Navigator.of(context).pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SelectHeaderStyleButton extends StatelessWidget {
  final quill.QuillController controller;

  const SelectHeaderStyleButton({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: const Text('Heading'),
      icon: const Icon(Icons.arrow_drop_down),
      underline: const SizedBox(),
      items: [
        DropdownMenuItem(
          value: 'Normal',
          child: const Text('Normal'),
          onTap: () => controller.formatSelection(null),
        ),
        DropdownMenuItem(
          value: 'H1',
          child: const Text('H1', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          onTap: () => controller.formatSelection(quill.Attribute.h1),
        ),
        DropdownMenuItem(
          value: 'H2',
          child: const Text('H2', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          onTap: () => controller.formatSelection(quill.Attribute.h2),
        ),
        DropdownMenuItem(
          value: 'H3',
          child: const Text('H3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          onTap: () => controller.formatSelection(quill.Attribute.h3),
        ),
      ],
      onChanged: (_) {},
    );
  }
}