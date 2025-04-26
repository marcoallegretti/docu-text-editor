import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../models/document_model.dart';
import '../services/document_storage.dart';
import '../services/platform_service.dart';
import '../services/export_service.dart';
import '../widgets/document_view.dart';
import '../widgets/export_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auto_save_provider.dart';

class EditorScreen extends StatefulWidget {
  final DocumentModel? initialDocument;

  const EditorScreen({Key? key, this.initialDocument}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late DocumentModel _document;
  String _documentTitle =
      'Untitled Document'; // Default value to prevent late initialization error
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showKeyboard = false;
  final DocumentStorage _storage = DocumentStorage();
  late AnimationController _animController;
  late Animation<double> _saveAnimation;

  @override
  void initState() {
    super.initState();
    _loadDocument();

    // Setup animation for save indicator
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _saveAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    // Add keyboard visibility listener
    KeyboardVisibilityController().onChange.listen((bool visible) {
      setState(() {
        _showKeyboard = visible;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    if (widget.initialDocument != null) {
      // Use the document that was passed in as an argument
      _document = widget.initialDocument!;
      _documentTitle = _document.title;
      setState(() {
        _isLoading = false;
      });
    } else {
      try {
        // Only get the recent document - don't automatically create a new one
        final recentId = await _storage.getRecentDocumentId();

        if (recentId != null) {
          // If there's a recent document, load it
          final document = await _storage.getDocument(recentId);
          if (document != null) {
            _document = document;
            _documentTitle = document.title;
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // If no recent document or it couldn't be loaded, create a new one
        final newDocument = DocumentModel.empty();
        await _storage.saveDocument(newDocument);
        await _storage.saveRecentDocument(newDocument.id);

        _document = newDocument;
        _documentTitle = newDocument.title;
      } catch (e) {
        // If there's an error, create a new document
        _document = DocumentModel.empty();
        _documentTitle = _document.title;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onContentChanged(QuillController controller) {
    _document.updateContent(controller);
    final autoSaveProvider = Provider.of<AutoSaveProvider>(context, listen: false);
    if (autoSaveProvider.isAutoSaveEnabled) {
      _saveDocument();
    }
  }

  Future<void> _saveDocument() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Animate the save indicator
    _animController.forward();

    // Save with a delay to prevent excessive saves
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await _storage.saveDocument(_document);
      // Show animation briefly after successful save
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Show error if saving fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving document: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _animController.reverse();
      }
    }
  }

  Future<void> _renameDocument() async {
    final TextEditingController titleController =
        TextEditingController(text: _documentTitle);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Enter document title',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            autofocus: true,
            onSubmitted: (_) {
              Navigator.of(context).pop();
              _updateTitle(titleController.text);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateTitle(titleController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateTitle(String newTitle) {
    setState(() {
      _documentTitle = newTitle.isNotEmpty ? newTitle : 'Untitled Document';
      _document.title = _documentTitle;
    });
    _saveDocument();
  }

  Future<void> _createNewDocument() async {
    // Create a new document with a unique ID
    final newDocument = DocumentModel.empty();

    // Save it to storage
    await _storage.saveDocument(newDocument);
    await _storage.saveRecentDocument(newDocument.id);

    if (mounted) {
      // First update the state of this screen
      setState(() {
        _document = newDocument;
        _documentTitle = newDocument.title;
      });

      // Navigate to the settings screen with replacement to prevent returning to this screen
      // with the old document still loaded
      Navigator.pushReplacementNamed(context, '/settings', arguments: {
        'newDocumentId': newDocument.id,
        'preventDocumentCreation': true
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformService.getDeviceType(context);
    final isDesktop = deviceType == DeviceType.desktop;
    final isTablet = deviceType == DeviceType.tablet;
    final isMobile = deviceType == DeviceType.mobile;

    return Scaffold(
      appBar: AppBar(
        title: _buildDocumentTitle(isDesktop),
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Manual save button when auto-save is disabled
          Consumer<AutoSaveProvider>(
            builder: (context, autoSaveProvider, _) {
              if (!autoSaveProvider.isAutoSaveEnabled && !_isSaving) {
                return IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save document',
                  onPressed: _saveDocument,
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // Save indicator
          AnimatedBuilder(
            animation: _saveAnimation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _isSaving
                    ? Row(
                        children: [
                          Text(
                            'Saving',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                              value: _saveAnimation.value,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : FadeTransition(
                        opacity: _saveAnimation,
                        child: Row(
                          children: [
                            Text(
                              'Saved',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
              );
            },
          ),

          // Document options menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Document options',
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _createNewDocument();
                  break;
                case 'rename':
                  _renameDocument();
                  break;
                case 'print':
                  ExportService.previewPdf(context, _document);
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 12),
                    Text('New Document'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              if (isDesktop || isTablet)
                const PopupMenuItem<String>(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 12),
                      Text('Print'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Floating action button fades out when keyboard appears on mobile
      floatingActionButton: isMobile
          ? AnimatedOpacity(
              opacity: _showKeyboard ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                onPressed: _createNewDocument,
                tooltip: 'New Document',
                child: const Icon(Icons.add),
                elevation: 2,
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DocumentView(
              document: _document,
              onContentChanged: _onContentChanged,
            ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(document: _document),
    );
  }

  Widget _buildDocumentTitle(bool isDesktop) {
    return GestureDetector(
      onTap: _renameDocument,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _documentTitle,
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 16),
          ],
        ),
      ),
    );
  }
}
