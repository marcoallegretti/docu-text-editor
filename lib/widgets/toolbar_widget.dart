import 'package:flutter/material.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme.dart';
import '../services/platform_service.dart';
import '../utils/quill_extensions.dart';
import 'font_selector_widget.dart';
import 'color_picker_widget.dart';

import 'font_size_selector.dart';
import 'link_dialog.dart';

class EditorToolbar extends StatefulWidget {
  final quill.QuillController controller;

  const EditorToolbar({Key? key, required this.controller}) : super(key: key);

  @override
  State<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar>
    with SingleTickerProviderStateMixin {
  void _handleInsertLink() async {
    final selection = widget.controller.selection;
    if (selection.baseOffset == selection.extentOffset) {
      // No text selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text to add a link.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if selection already has a link
    final attrs = widget.controller.getSelectionStyle().attributes;
    final existingLink = attrs.containsKey('a') ? attrs['a']?.value as String? : null;

    showDialog(
      context: context,
      builder: (context) => LinkDialog(
        initialUrl: existingLink,
        onSubmit: (url) {
          if (url.isEmpty) {
            widget.controller.formatSelection(quill.Attribute.clone(quill.Attribute.link, null));
          } else {
            widget.controller.formatSelection(quill.LinkAttribute(url));
          }
        },
      ),
    );
  }

  final FocusNode _keyboardFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = PlatformService.isDesktopPlatform();
    final isMobile = PlatformService.isMobileScreen(context);


    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkToolbarColor : AppTheme.toolbarColor,
        borderRadius: BorderRadius.circular(isMobile ? 0 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                // Main formatting tools that always show
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolButton(
                          icon: Icons.undo_rounded,
                          tooltip: 'Undo',
                          onPressed: () => widget.controller.undo(),
                        ),
                        _buildToolButton(
                          icon: Icons.redo_rounded,
                          tooltip: 'Redo',
                          onPressed: () => widget.controller.redo(),
                        ),
                        const ToolbarDivider(),

                        _buildStyleButton(
                          icon: Icons.format_bold_rounded,
                          tooltip: 'Bold',
                          attribute: quill.Attribute.bold,
                        ),
                        _buildStyleButton(
                          icon: Icons.format_italic_rounded,
                          tooltip: 'Italic',
                          attribute: quill.Attribute.italic,
                        ),
                        _buildStyleButton(
                          icon: Icons.format_underline_rounded,
                          tooltip: 'Underline',
                          attribute: quill.Attribute.underline,
                        ),
                        _buildToolButton(
                          icon: Icons.link,
                          tooltip: 'Insert Link',
                          onPressed: _handleInsertLink,
                        ),

                        const ToolbarDivider(),

                        PopupMenuButton(
                          tooltip: 'Text alignment',
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 8),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.format_align_left_rounded,
                                      size: 20),
                                  const Icon(Icons.arrow_drop_down, size: 14),
                                ],
                              ),
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => widget.controller.formatSelection(
                                  quill.Attribute.leftAlignment),
                              child: Row(
                                children: [
                                  Icon(Icons.format_align_left_rounded,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Align left'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => widget.controller.formatSelection(
                                  quill.Attribute.centerAlignment),
                              child: Row(
                                children: [
                                  Icon(Icons.format_align_center_rounded,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Align center'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => widget.controller.formatSelection(
                                  quill.Attribute.rightAlignment),
                              child: Row(
                                children: [
                                  Icon(Icons.format_align_right_rounded,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Align right'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => widget.controller.formatSelection(
                                  quill.Attribute.justifyAlignment),
                              child: Row(
                                children: [
                                  Icon(Icons.format_align_justify_rounded,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Justify'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const ToolbarDivider(),

                        // Font selector popup
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FontSelectorWidget(
                            controller: widget.controller,
                            onFontSelected: (fontName) {
                              // Apply font family to selected text
                              final attribute = quill.Attribute.fromKeyValue(
                                  'font', fontName);
                              widget.controller.formatSelection(attribute);
                            },
                          ),
                        ),

                        // Font size selector
                        FontSizeSelector(controller: widget.controller),

                        // Color pickers - improved implementation
                        Tooltip(
                          message: 'Text color',
                          child: AdvancedColorPickerWidget(
                            controller: widget.controller,
                            isBackground: false,
                          ),
                        ),
                        Tooltip(
                          message: 'Highlight color',
                          child: AdvancedColorPickerWidget(
                            controller: widget.controller,
                            isBackground: true,
                          ),
                        ),

                        if (screenWidth >= 500) ...[
                          const ToolbarDivider(),
                          _buildStyleButton(
                            icon: Icons.format_list_bulleted_rounded,
                            tooltip: 'Bullet list',
                            attribute: quill.Attribute.ul,
                          ),
                          _buildStyleButton(
                            icon: Icons.format_list_numbered_rounded,
                            tooltip: 'Numbered list',
                            attribute: quill.Attribute.ol,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Expand/Collapse button
                if (!isDesktop)
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: _isExpanded ? 'Show less' : 'Show more options',
                    onPressed: _toggleExpanded,
                  ),
              ],
            ),
          ),

          // Expandable section
          if (!isDesktop)
            SizeTransition(
              sizeFactor: _fadeAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (screenWidth < 500) ...[
                              _buildStyleButton(
                                icon: Icons.format_list_bulleted_rounded,
                                tooltip: 'Bullet list',
                                attribute: quill.Attribute.ul,
                              ),
                              _buildStyleButton(
                                icon: Icons.format_list_numbered_rounded,
                                tooltip: 'Numbered list',
                                attribute: quill.Attribute.ol,
                              ),
                              const ToolbarDivider(),

                              // Font family selector
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FontSelectorWidget(
                                  controller: widget.controller,
                                  onFontSelected: (fontName) {
                                    // Apply font family to selected text using our extension method
                                    widget.controller.applyFontFamily(fontName);

                                    // Log for debugging
                                    print('Applied font: $fontName');
                                  },
                                ),
                              ),

                              // Font size selector
                              FontSizeSelector(controller: widget.controller),

                              // Color pickers - improved implementation
                              AdvancedColorPickerWidget(
                                controller: widget.controller,
                                isBackground: false,
                              ),
                              AdvancedColorPickerWidget(
                                controller: widget.controller,
                                isBackground: true,
                              ),

                              const ToolbarDivider(),
                            ],
                            _buildStyleButton(
                              icon: Icons.format_strikethrough_rounded,
                              tooltip: 'Strikethrough',
                              attribute: quill.Attribute.strikeThrough,
                            ),
                            _buildToolButton(
                              icon: Icons.format_clear_rounded,
                              tooltip: 'Clear formatting',
                              onPressed: () =>
                                  widget.controller.formatSelection(null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Desktop shortcuts removed per request
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon,
                size: 20,
                color:
                    isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleButton({
    required IconData icon,
    required String tooltip,
    required quill.Attribute attribute,
  }) {
    // Use StatefulBuilder for more flexibility
    return StatefulBuilder(
      builder: (context, setState) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        // Check if the attribute is already applied to the current selection
        final style = widget.controller.getSelectionStyle();
        final isActive = style.containsKey(attribute.key) &&
            style.attributes[attribute.key]?.value == attribute.value;

        final primaryColor =
            isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
        final textColor =
            isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor;

        return Tooltip(
          message: tooltip,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color:
                  isActive ? primaryColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                // Toggle the attribute - if it's active, remove it, otherwise add it
                if (isActive) {
  // Special handling for lists
  if (attribute == quill.Attribute.ul ||
      attribute == quill.Attribute.ol) {
    _removeListFormat(widget.controller, attribute);
  } else {
    // For other attributes, remove the formatting using clone
    widget.controller.formatSelection(
      quill.Attribute.clone(attribute, null),
    );
  }
} else {
  widget.controller.formatSelection(attribute);
}
                // Force refresh this widget
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? primaryColor : textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to properly remove list formatting
  void _removeListFormat(
      quill.QuillController controller, quill.Attribute attribute) {
    // We'll use a simpler approach
    if (attribute == quill.Attribute.ul) {
      // For bullet lists
      controller
          .formatSelection(quill.Attribute.clone(quill.Attribute.ul, null));
    } else if (attribute == quill.Attribute.ol) {
      // For numbered lists
      controller
          .formatSelection(quill.Attribute.clone(quill.Attribute.ol, null));
    }
  }

}

class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 20,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
      ),
    );
  }
}

class WordCountDisplay extends StatelessWidget {
  final int wordCount;
  final int pageCount;

  const WordCountDisplay({
    Key? key,
    required this.wordCount,
    required this.pageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkToolbarColor : AppTheme.toolbarColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Add some more info on larger screens
          if (MediaQuery.of(context).size.width > 500)
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppTheme.secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  'Auto-saved',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                ),
              ],
            )
          else
            const SizedBox(),

          // Word count info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.text_fields,
                    size: 14, color: AppTheme.secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  '$wordCount ${wordCount == 1 ? "word" : "words"} · $pageCount ${pageCount == 1 ? "page" : "pages"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaginationIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PaginationIndicator({
    Key? key,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color:
                    isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              style: IconButton.styleFrom(
                backgroundColor: isDarkMode
                    ? (currentPage > 1
                        ? Colors.grey.shade800
                        : Colors.grey.shade900)
                    : (currentPage > 1
                        ? Colors.grey.shade200
                        : Colors.grey.shade100),
                foregroundColor: currentPage > 1
                    ? (isDarkMode
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor)
                    : Colors.grey,
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
              ),
              onPressed: currentPage > 1 ? () {} : null,
              tooltip: 'Previous Page',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Page $currentPage of $totalPages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              style: IconButton.styleFrom(
                backgroundColor: isDarkMode
                    ? (currentPage < totalPages
                        ? Colors.grey.shade800
                        : Colors.grey.shade900)
                    : (currentPage < totalPages
                        ? Colors.grey.shade200
                        : Colors.grey.shade100),
                foregroundColor: currentPage < totalPages
                    ? (isDarkMode
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor)
                    : Colors.grey,
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
              ),
              onPressed: currentPage < totalPages ? () {} : null,
              tooltip: 'Next Page',
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Page 1',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
