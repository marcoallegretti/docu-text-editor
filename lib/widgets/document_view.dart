import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../theme.dart';
import '../models/document_model.dart';
import '../services/platform_service.dart';
import '../services/export_service.dart';
import '../utils/word_counter.dart';
import 'pagination_indicator.dart' as pagination;
import 'toolbar_widget.dart';

// VoidCallbackIntent class for keyboard shortcuts
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}

class DocumentView extends StatefulWidget {
  final DocumentModel document;
  final Function(quill.QuillController) onContentChanged;

  const DocumentView({
    Key? key,
    required this.document,
    required this.onContentChanged,
  }) : super(key: key);

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView>
    with SingleTickerProviderStateMixin {
  List<String> _pages = [];
  List<int> _pageStartIndices = [
    0
  ]; // Store character indices where each page starts

  double _marginTop = 40.0;
  double _marginBottom = 40.0;
  double _marginLeft = 40.0;
  double _marginRight = 40.0;

  late ScrollController _scrollController;
  int _wordCount = 0;
  int _pageCount = 1;
  int _currentPage = 1;
  bool _isEditorFocused = false;
  final FocusNode _editorFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _toolbarAnimation;
  late Animation<double> _paperAnimation;
  bool _showToolbar = true;

  late quill.QuillController _controller;

  // Keyboard shortcut bindings
  final Map<ShortcutActivator, VoidCallback> _shortcuts = {};

  // Split document into pages by word count (250 words per page)
  void _splitDocumentIntoPages() {
    final text = _controller.document.toPlainText();
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    const wordsPerPage = 250;

    // Calculate total pages
    final totalPages =
        words.isEmpty ? 1 : ((words.length - 1) ~/ wordsPerPage) + 1;

    // Create page content and indices
    _pages = [];
    _pageStartIndices = [0]; // First page always starts at index 0

    // Process each word to find page boundaries
    int currentCharIndex = 0;

    for (int i = 0; i < words.length; i++) {
      // When we reach a page boundary, record the character index
      if (i > 0 && i % wordsPerPage == 0) {
        _pageStartIndices.add(currentCharIndex);
      }

      // Add the word length plus space
      currentCharIndex += words[i].length + 1; // +1 for space
    }

    // Create page content for display (optional)
    for (int i = 0; i < totalPages; i++) {
      final startWord = i * wordsPerPage;
      final endWord = ((i + 1) * wordsPerPage > words.length)
          ? words.length
          : (i + 1) * wordsPerPage;
      final pageContent = words.sublist(startWord, endWord).join(' ');
      _pages.add(pageContent);
    }

    // Ensure we have at least one page
    if (_pages.isEmpty) {
      _pages.add('');
      _pageStartIndices = [0];
    }

    // Update page count in state
    setState(() {
      _pageCount = totalPages;
      // Ensure current page is valid
      if (_currentPage > _pageCount) {
        _currentPage = _pageCount;
      }
    });
  }

  void _goToPage(int page) {
    // Validate page number
    if (page < 1) page = 1;
    if (page > _pageCount) page = _pageCount;

    // Only update if we're actually changing pages
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });

      // Scroll to the start of the page in the editor
      _scrollToPage(page);
    }
  }

  void _scrollToPage(int page) {
    if (_pageStartIndices.isEmpty ||
        page < 1 ||
        page > _pageStartIndices.length) {
      return;
    }

    // Get the pre-calculated character index for this page
    final charIndex = _pageStartIndices[page - 1];

    // Move cursor to the start of the page
    _controller.updateSelection(
      TextSelection.collapsed(offset: charIndex),
      quill.ChangeSource.local,
    );

    // Scroll to the position
    // We need a small delay to ensure the editor has updated
    Future.delayed(const Duration(milliseconds: 50), () {
      // Calculate approximate scroll position based on character position
      // This is a heuristic that works reasonably well for most documents
      double approximateScrollPosition;

      if (_controller.document.length > 0) {
        // Calculate position as a percentage of document length
        final percentage = charIndex / _controller.document.length;
        approximateScrollPosition =
            percentage * _scrollController.position.maxScrollExtent;
      } else {
        approximateScrollPosition = 0;
      }

      // Ensure we don't scroll beyond limits
      final scrollPosition = approximateScrollPosition.clamp(
          0.0, _scrollController.position.maxScrollExtent);

      // Animate to the position
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // Properly initialize the QuillController with the document's content
    _controller = widget.document.toQuillController();
    _scrollController = ScrollController();
    _splitDocumentIntoPages();
    _controller.addListener(_onEditorChanged);
    // Add a listener to the document to trigger autosave
    _controller.document.changes.listen(_handleDocumentChange);
    _editorFocusNode.addListener(_handleFocusChange);
    // Properly initialize animation controller and animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _toolbarAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _paperAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.value = 1.0; // Show toolbar by default
    _updateWordAndPageCount();
  }

  void _onEditorChanged() {
    // Re-split document into pages on every change
    _splitDocumentIntoPages();
    _updateWordAndPageCount();

    // Calculate which page the cursor is currently on
    _updateCurrentPageFromCursor();
    widget.document.updateContent(_controller);
  }

  void _updateCurrentPageFromCursor() {
    // Get current cursor position
    final cursorOffset = _controller.selection.baseOffset;

    // Handle empty document case
    if (_controller.document.length == 0 || _pageStartIndices.isEmpty) {
      setState(() {
        _currentPage = 1;
      });
      return;
    }

    // Find which page contains this cursor position
    for (int i = 0; i < _pageStartIndices.length; i++) {
      final startIndex = _pageStartIndices[i];
      final endIndex = (i < _pageStartIndices.length - 1)
          ? _pageStartIndices[i + 1]
          : _controller.document.length;

      if (cursorOffset >= startIndex && cursorOffset < endIndex) {
        if (_currentPage != i + 1) {
          setState(() {
            _currentPage = i + 1;
          });
        }
        break;
      }
    }

    // If cursor is at the very end of the document, put it on the last page
    if (cursorOffset == _controller.document.length && _pageCount > 0) {
      setState(() {
        _currentPage = _pageCount;
      });
    }
  }

  void _updateWordAndPageCount() {
    final text = _controller.document.toPlainText();
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    setState(() {
      _wordCount = words.length;
      _pageCount = ((words.length - 1) ~/ 250) + 1;
      // Ensure we have at least one page
      if (_pageCount < 1) _pageCount = 1;

      // Make sure current page is valid
      if (_currentPage > _pageCount) {
        _currentPage = _pageCount;
      }
    });
  }

  // Insert image at cursor
  void _insertImage() {
    debugPrint('_insertImage called');
    // Make sure editor is focused
    FocusScope.of(context).requestFocus(_editorFocusNode);

    try {
      // For demo, we'll insert a placeholder image
      // In a real app, you would show an image picker dialog
      final imageUrl = 'https://place-hold.it/300x200';

      // First insert a new line to ensure the image is on its own line
      final index = _controller.selection.baseOffset;
      debugPrint('Current selection index: $index');
      _controller.replaceText(index, 0, '\n', null);

      // Insert the image embed
      debugPrint('Inserting image at index: ${index + 1}');
      _controller.replaceText(
        index + 1, // After the newline
        0,
        quill.BlockEmbed.image(imageUrl),
        null,
      );

      // Add another newline after the image
      _controller.replaceText(index + 2, 0, '\n', null);

      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image inserted')),
      );
      debugPrint('Image insertion completed successfully');
    } catch (e) {
      debugPrint('Error inserting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting image: ${e.toString()}')),
      );
    }
  }

  // Table insertion is not supported in this implementation.
  // void _insertTable() { // Removed
  // }

  // Insert divider at cursor
  void _insertDivider() {
    // Make sure editor is focused
    FocusScope.of(context).requestFocus(_editorFocusNode);

    try {
      // First insert a new line to ensure the divider is on its own line
      final index = _controller.selection.baseOffset;
      _controller.replaceText(index, 0, '\n', null);

      // Insert the divider (horizontal rule)
      _controller.replaceText(
        index + 1, // After the newline
        0,
        quill.BlockEmbed('divider', 'true'),
        null,
      );

      // Add another newline after the divider
      _controller.replaceText(index + 2, 0, '\n', null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Divider inserted')),
      );
    } catch (e) {
      debugPrint('Error inserting divider: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting divider: ${e.toString()}')),
      );
    }
  }

  // Insert blockquote at cursor
  void _insertBlockquote() {
    // Make sure editor is focused
    FocusScope.of(context).requestFocus(_editorFocusNode);

    try {
      final index = _controller.selection.baseOffset;

      // Insert text for the blockquote if there's no selection
      if (_controller.selection.baseOffset ==
          _controller.selection.extentOffset) {
        _controller.replaceText(index, 0, 'Type your quote here', null);
      }

      // Apply blockquote formatting
      _controller.formatText(
        index,
        _controller.selection.extentOffset - index > 0
            ? _controller.selection.extentOffset - index
            : 'Type your quote here'.length,
        quill.Attribute.blockQuote,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blockquote inserted')),
      );
    } catch (e) {
      debugPrint('Error inserting blockquote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting blockquote: ${e.toString()}')),
      );
    }
  }

  // Insert code block at cursor
  void _insertCodeBlock() {
    // Make sure editor is focused
    FocusScope.of(context).requestFocus(_editorFocusNode);

    try {
      final index = _controller.selection.baseOffset;

      // Insert sample code if there's no selection
      if (_controller.selection.baseOffset ==
          _controller.selection.extentOffset) {
        _controller.replaceText(index, 0, 'print("Hello, world!");', null);
      }

      // Apply code block formatting
      _controller.formatText(
        index,
        _controller.selection.extentOffset - index > 0
            ? _controller.selection.extentOffset - index
            : 'print("Hello, world!");'.length,
        quill.Attribute.codeBlock,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code block inserted')),
      );
    } catch (e) {
      debugPrint('Error inserting code block: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting code block: ${e.toString()}')),
      );
    }
  }

  // Show page settings dialog
  void _showPageSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Page Settings'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add your page settings controls here
            Text('Page size, margins, orientation, etc.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // Export document to various formats
  void _exportDocument() {
    // Print the visible text before exporting for debugging
    debugPrint('EDITOR VISIBLE TEXT: ' + _controller.document.toPlainText());
    // Update the widget.document content from the current controller before export
    widget.document.updateContent(_controller);
    // Create a DocumentModel from the updated widget.document
    final document = DocumentModel(
      id: widget.document.id,
      title: widget.document.title,
      content: widget.document.content,
      createdAt: widget.document.createdAt,
      updatedAt: DateTime.now(),
      wordCount: widget.document.wordCount,
      pageCount: widget.document.pageCount,
    );
    final deltaJson = _controller.document.toDelta().toJson();
    final plainText = _controller.document.toPlainText();
    debugPrint('EXPORT: Controller delta: ' + deltaJson.toString());
    debugPrint('EXPORT: Controller plain text: ' + plainText);

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Export Document'),
          ],
        ),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              final loadingSnackBar = SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 16),
                    Text('Exporting PDF...'),
                  ],
                ),
                duration: Duration(seconds: 1),
              );
              ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

              // Export as PDF
              final success = await ExportService.exportDocument(
                  context, document, ExportFormat.pdf);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document exported as PDF')),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Export as PDF'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              final loadingSnackBar = SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 16),
                    Text('Exporting HTML...'),
                  ],
                ),
                duration: Duration(seconds: 1),
              );
              ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

              // Export as HTML
              final success = await ExportService.exportDocument(
                  context, document, ExportFormat.html);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document exported as HTML')),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Export as HTML'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              final loadingSnackBar = SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 16),
                    Text('Exporting Plain Text...'),
                  ],
                ),
                duration: Duration(seconds: 1),
              );
              ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

              // Export as Plain Text
              final success = await ExportService.exportDocument(
                  context, document, ExportFormat.plainText);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Document exported as Plain Text')),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Export as Plain Text'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to check if tap is inside text content
  bool _isPositionOnText(Offset position) {
    // Consider any selection as being on text
    if (_controller.selection.baseOffset !=
        _controller.selection.extentOffset) {
      return true;
    }

    // For simplicity, we'll use a heuristic - if the position is close to text content
    // This is a simplification and would need more precise hit testing in a real app
    // Check if document has any content at all
    if (_controller.document.length > 0) {
      // Basic heuristic to determine if we're likely clicking on text
      // A real implementation would do actual hit-testing with the render objects
      return true;
    }

    return false;
  }

  // Show text formatting context menu
  void _showTextContextMenu(Offset position) {
    final RelativeRect rect = RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1);

    showMenu<String>(
      context: context,
      position: rect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        const PopupMenuItem<String>(
          value: 'bold',
          child: Row(
            children: [
              Icon(Icons.format_bold, size: 18),
              SizedBox(width: 8),
              Text('Bold'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'italic',
          child: Row(
            children: [
              Icon(Icons.format_italic, size: 18),
              SizedBox(width: 8),
              Text('Italic'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'underline',
          child: Row(
            children: [
              Icon(Icons.format_underline, size: 18),
              SizedBox(width: 8),
              Text('Underline'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'strikethrough',
          child: Row(
            children: [
              Icon(Icons.format_strikethrough, size: 18),
              SizedBox(width: 8),
              Text('Strikethrough'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'cut',
          child: Row(
            children: [
              Icon(Icons.content_cut, size: 18),
              SizedBox(width: 8),
              Text('Cut'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.content_paste, size: 18),
              SizedBox(width: 8),
              Text('Paste'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'selectAll',
          child: Row(
            children: [
              Icon(Icons.select_all, size: 18),
              SizedBox(width: 8),
              Text('Select All'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      // Handle the selected item
      FocusScope.of(context).requestFocus(_editorFocusNode);

      switch (value) {
        case 'bold':
          _controller.formatSelection(quill.Attribute.bold);
          break;
        case 'italic':
          _controller.formatSelection(quill.Attribute.italic);
          break;
        case 'underline':
          _controller.formatSelection(quill.Attribute.underline);
          break;
        case 'strikethrough':
          _controller.formatSelection(quill.Attribute.strikeThrough);
          break;
        case 'cut':
          _cutText();
          break;
        case 'copy':
          _copyText();
          break;
        case 'paste':
          _pasteText();
          break;
        case 'selectAll':
          _selectAllText();
          break;
      }
    });
  }

  // Show workspace context menu
  void _showWorkspaceContextMenu(Offset position) {
    final RelativeRect rect = RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1);

    showMenu<String>(
      context: context,
      position: rect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        const PopupMenuItem<String>(
          value: 'image',
          child: Row(
            children: [
              Icon(Icons.image_outlined, size: 18),
              SizedBox(width: 8),
              Text('Insert Image'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'divider',
          child: Row(
            children: [
              Icon(Icons.horizontal_rule, size: 18),
              SizedBox(width: 8),
              Text('Insert Divider'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'blockquote',
          child: Row(
            children: [
              Icon(Icons.format_quote_outlined, size: 18),
              SizedBox(width: 8),
              Text('Insert Blockquote'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'codeblock',
          child: Row(
            children: [
              Icon(Icons.code, size: 18),
              SizedBox(width: 8),
              Text('Insert Code Block'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 8),
              Text('Page Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, size: 18),
              SizedBox(width: 8),
              Text('Export Document'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      // Handle the selected item
      switch (value) {
        case 'image':
          _insertImage();
          break;

        case 'divider':
          _insertDivider();
          break;
        case 'blockquote':
          _insertBlockquote();
          break;
        case 'codeblock':
          _insertCodeBlock();
          break;
        case 'settings':
          _showPageSettings();
          break;
        case 'export':
          _exportDocument();
          break;
      }
    });
  }

  // Helper methods for clipboard operations
  void _cutText() async {
    final text = _controller.document.getPlainText(
      _controller.selection.start,
      _controller.selection.end,
    );
    await Clipboard.setData(ClipboardData(text: text));
    _controller.replaceText(
      _controller.selection.start,
      _controller.selection.end - _controller.selection.start,
      '',
      null,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cut to clipboard')),
    );
  }

  void _copyText() async {
    final text = _controller.document.getPlainText(
      _controller.selection.start,
      _controller.selection.end,
    );
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _controller.replaceText(
        _controller.selection.start,
        _controller.selection.end - _controller.selection.start,
        data.text!,
        null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasted from clipboard')),
      );
    }
  }

  void _selectAllText() {
    final documentLength = _controller.document.length;
    _controller.updateSelection(
      TextSelection(baseOffset: 0, extentOffset: documentLength),
      quill.ChangeSource.local,
    );
  }

  // Removed duplicate initState to resolve error

  void _handleScroll() {
    if (!PlatformService.isDesktopPlatform()) {
      if (_scrollController.offset > 20 && _showToolbar) {
        setState(() {
          _showToolbar = false;
          _animController.reverse();
        });
      } else if (_scrollController.offset <= 20 && !_showToolbar) {
        setState(() {
          _showToolbar = true;
          _animController.forward();
        });
      }
    }
  }

  void _setupKeyboardShortcuts() {
    // Define common keyboard shortcuts
    _shortcuts.addAll({
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): () {
        _controller.formatSelection(quill.Attribute.bold);
      },
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): () {
        _controller.formatSelection(quill.Attribute.italic);
      },
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU): () {
        _controller.formatSelection(quill.Attribute.underline);
      },
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): () {
        _controller.formatSelection(quill.Attribute.h1);
      },
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): () {
        _controller.formatSelection(quill.Attribute.h2);
      },
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): () {
        _controller.formatSelection(quill.Attribute.h3);
      },
    });
  }

  void _handleFocusChange() {
    setState(() {
      _isEditorFocused = _editorFocusNode.hasFocus;

      // Show toolbar when focus gained
      if (_isEditorFocused && !_showToolbar) {
        _showToolbar = true;
        _animController.forward();
      }
    });
  }

  void _handleDocumentChange(dynamic _) {
    // Update word count when document changes
    _updateWordCount();
    widget.onContentChanged(_controller);
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = WordCounter.countWords(_controller);
      _pageCount = WordCounter.estimatePageCount(_wordCount);
    });
  }

  void _showPageMarginDialog() async {
    final topController =
        TextEditingController(text: _marginTop.toStringAsFixed(0));
    final bottomController =
        TextEditingController(text: _marginBottom.toStringAsFixed(0));
    final leftController =
        TextEditingController(text: _marginLeft.toStringAsFixed(0));
    final rightController =
        TextEditingController(text: _marginRight.toStringAsFixed(0));
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Page Margins'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: Text('Top')),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: topController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                  ),
                ),
              ]),
              SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Bottom')),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: bottomController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                  ),
                ),
              ]),
              SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Left')),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: leftController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                  ),
                ),
              ]),
              SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Right')),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: rightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                  ),
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _marginTop =
                      double.tryParse(topController.text) ?? _marginTop;
                  _marginBottom =
                      double.tryParse(bottomController.text) ?? _marginBottom;
                  _marginLeft =
                      double.tryParse(leftController.text) ?? _marginLeft;
                  _marginRight =
                      double.tryParse(rightController.text) ?? _marginRight;
                });
                Navigator.of(context).pop(true);
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Ensure the latest content is saved before disposing
    widget.document.updateContent(_controller);
    widget.onContentChanged(_controller);
    
    _controller.dispose();
    _scrollController.dispose();
    _editorFocusNode.removeListener(_handleFocusChange);
    _editorFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformService.getDeviceType(context);
    final isDesktop = deviceType == DeviceType.desktop;
    final isTablet = deviceType == DeviceType.tablet;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set max width based on device type
    final maxWidth = isDesktop
        ? 900.0
        : isTablet
            ? 700.0
            : 500.0;

    // Use shortcuts on desktop
    Widget editorWidget = Column(
      children: [
        // Toolbar - bigger buttons on mobile
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(_toolbarAnimation),
          child: FadeTransition(
            opacity: _toolbarAnimation,
            child: EditorToolbar(controller: _controller),
          ),
        ),

        // Document editing area
        Expanded(
          child: Container(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth, // Adjust based on device type
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(_paperAnimation),
                  child: FadeTransition(
                    opacity: _paperAnimation,
                    child: Stack(
                      children: [
                        // Editor content (first, fills stack)
                        Container(
                          padding: EdgeInsets.fromLTRB(_marginLeft, _marginTop,
                              _marginRight, _marginBottom),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(isDesktop ? 3 : 0),
                            color: isDarkMode
                                ? AppTheme.darkPaperColor
                                : AppTheme.paperColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                    ((isDarkMode ? 0.2 : 0.05) * 255).toInt()),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                    ((isDarkMode ? 0.2 : 0.05) * 255).toInt()),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(isDesktop ? 3 : 0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onSecondaryTapDown: isDesktop
                                        ? (details) {
                                            final RenderBox box =
                                                context.findRenderObject()
                                                    as RenderBox;
                                            final localPosition =
                                                box.globalToLocal(
                                                    details.globalPosition);
                                            final isTextSelected = _controller
                                                    .selection.baseOffset !=
                                                _controller
                                                    .selection.extentOffset;
                                            final isOnText = isTextSelected ||
                                                _isPositionOnText(
                                                    localPosition);
                                            if (isOnText) {
                                              _showTextContextMenu(
                                                  details.globalPosition);
                                            } else {
                                              _showWorkspaceContextMenu(
                                                  details.globalPosition);
                                            }
                                          }
                                        : null,
                                    child: quill.QuillEditor(
                                      controller: _controller,
                                      focusNode: _editorFocusNode,
                                      scrollController: _scrollController,
                                      config: quill.QuillEditorConfig(

                                          // Add other config options here if needed
                                          ),
                                    ),
                                    // Table embeds are not supported due to dependency constraints. Remove tables from document data to avoid runtime errors.
                                    //       final rows = (tableData['rows'] ?? 2) as int;
                                    //       final columns = (tableData['columns'] ?? 2) as int;
                                    //       return SingleChildScrollView(
                                    //         scrollDirection: Axis.horizontal,
                                    //         child: Table(
                                    //           border: TableBorder.all(),
                                    //           defaultColumnWidth: const FixedColumnWidth(80),
                                    //           children: List.generate(rows, (r) {
                                    //             return TableRow(
                                    //               children: List.generate(columns, (c) {
                                    //                 return Padding(
                                    //                   padding: const EdgeInsets.all(8.0),
                                    //                   child: Text('R 2${r + 1}C 2${c + 1}'),
                                    //                 );
                                    //               }),
                                    //             );
                                    //           }),
                                    //         ),
                                    //       );
                                    //     }
                                    //     return const SizedBox.shrink();
                                    //   }
                                    // ],
                                  ),
                                ),
                                pagination.PaginationIndicator(
                                  currentPage: _currentPage,
                                  totalPages: _pageCount,
                                  onPrev: () => _goToPage(_currentPage - 1),
                                  onNext: () => _goToPage(_currentPage + 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Margin settings button (top-right, does not block editor)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                              icon: Icon(Icons.crop_square,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54),
                              tooltip: 'Page Margins',
                              onPressed: _showPageMarginDialog,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Word count display
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(_toolbarAnimation),
          child: FadeTransition(
            opacity: _toolbarAnimation,
            child: WordCountDisplay(
              wordCount: _wordCount,
              pageCount: _pageCount,
            ),
          ),
        ),
      ],
    );

    // Do NOT wrap the editorWidget with extra Focus/Shortcuts/Actions if it already contains QuillEditor
    return editorWidget;
  }
}
