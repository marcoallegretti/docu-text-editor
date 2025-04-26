import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../services/document_storage.dart';
import '../services/platform_service.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auto_save_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const SettingsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final DocumentStorage _storage = DocumentStorage();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  late TabController _tabController;
  final List<String> _tabs = ['Documents', 'Preferences', 'About'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      // Load documents from storage
      final documents = await _storage.getDocuments();

      // Sort documents by most recently edited
      documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Check for duplicates with the same title and content (created within a few seconds of each other)
      // This is a safeguard against rare cases where duplicates might be created
      final uniqueDocuments = <DocumentModel>[];
      final seenIds = <String>{};

      for (final doc in documents) {
        if (!seenIds.contains(doc.id)) {
          uniqueDocuments.add(doc);
          seenIds.add(doc.id);
        }
      }

      // If we found and removed duplicates, save the cleaned list back to storage
      if (uniqueDocuments.length != documents.length) {
        await _storage.saveDocuments(uniqueDocuments);
      }

      if (mounted) {
        setState(() {
          _documents = uniqueDocuments;
          _isLoading = false;
        });

        // If we have a newDocumentId from arguments, make sure we select the Documents tab
        if (widget.arguments != null &&
            widget.arguments!.containsKey('newDocumentId')) {
          // Ensure we're on the Documents tab (index 0)
          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _documents = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createNewDocument() async {
    // Create a new document with a unique ID
    final newDocument = DocumentModel.empty();

    // Before saving, check if this ID already exists to prevent duplication
    // (in case there's a race condition or similar issue)
    final documents = await _storage.getDocuments();
    final exists = documents.any((doc) => doc.id == newDocument.id);

    if (!exists) {
      // Only save if the document doesn't already exist
      await _storage.saveDocument(newDocument);
    }

    // Save as the recent document for consistency
    await _storage.saveRecentDocument(newDocument.id);

    // Navigate to the editor with the new document
    Navigator.pushReplacementNamed(context, '/editor', arguments: newDocument);
  }

  Future<void> _openDocument(DocumentModel document) async {
    await _storage.saveRecentDocument(document.id);
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/editor', arguments: document);
  }

  Future<void> _deleteDocument(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: const Text(
                'Are you sure you want to delete this document? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _storage.deleteDocument(id);
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformService.getDeviceType(context);
    final isDesktop = deviceType == DeviceType.desktop;
    final isTablet = deviceType == DeviceType.tablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton(
              onPressed: _createNewDocument,
              tooltip: 'New Document',
              child: const Icon(Icons.add),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Documents Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDocumentsTab(context, isDesktop || isTablet),

          // Preferences Tab
          _buildPreferencesTab(context, isDesktop || isTablet),

          // About Tab
          _buildAboutTab(context, isDesktop || isTablet),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context, bool isLargeScreen) {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No documents yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new document to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewDocument,
              icon: const Icon(Icons.add),
              label: const Text('Create New Document'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Documents',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${_documents.length} document${_documents.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLargeScreen ? _buildDocumentGrid() : _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentList() {
    return ListView.separated(
      itemCount: _documents.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final document = _documents[index];
        return _buildDocumentListItem(document);
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _openDocument(document),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document header with color
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last edited: ${_formatDate(document.updatedAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Document stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${document.wordCount} words',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${document.pageCount} page${document.pageCount == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteDocument(document.id),
                tooltip: 'Delete',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(DocumentModel document) {
    return ListTile(
      title: Text(document.title),
      subtitle: Text(
        'Last edited: ${_formatDate(document.updatedAt)} u2022 ${document.wordCount} words',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.description_outlined,
            color: AppTheme.primaryColor),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteDocument(document.id),
        tooltip: 'Delete',
      ),
      onTap: () => _openDocument(document),
    );
  }

  Widget _buildPreferencesTab(BuildContext context, bool isLargeScreen) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            'App Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Theme setting
          Card(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.color_lens,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                final currentTheme = themeProvider.isDarkTheme
                                    ? 'Dark'
                                    : 'Light';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Theme',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Currently set to: $currentTheme',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.wb_sunny,
                                            size: 16,
                                            color: !themeProvider.isDarkTheme
                                                ? AppTheme.primaryColor
                                                : Colors.grey),
                                        Expanded(
                                          child: Slider(
                                            value: themeProvider.isDarkTheme
                                                ? 1.0
                                                : 0.0,
                                            min: 0.0,
                                            max: 1.0,
                                            divisions: 1,
                                            activeColor: AppTheme.primaryColor,
                                            onChanged: (value) {
                                              themeProvider
                                                  .setDarkTheme(value > 0.5);
                                            },
                                          ),
                                        ),
                                        Icon(Icons.nightlight_round,
                                            size: 16,
                                            color: themeProvider.isDarkTheme
                                                ? AppTheme.primaryColor
                                                : Colors.grey),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Switch(
                            value: themeProvider.isDarkTheme,
                            onChanged: (value) {
                              themeProvider.setDarkTheme(value);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value
                                      ? 'Dark theme enabled'
                                      : 'Light theme enabled'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: value
                                      ? AppTheme.darkPrimaryColor
                                      : AppTheme.primaryColor,
                                ),
                              );
                            },
                            activeColor: AppTheme.primaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Editor settings
          Text(
            'Editor Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auto-save setting (implemented but toggle not functional)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.save, color: AppTheme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-Save',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Consumer<AutoSaveProvider>(
                              builder: (context, autoSaveProvider, _) {
                                return Text(
                                  autoSaveProvider.isAutoSaveEnabled
                                      ? 'Documents are automatically saved as you type'
                                      : 'Auto-save is disabled, changes must be saved manually',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Consumer<AutoSaveProvider>(
                        builder: (context, autoSaveProvider, _) {
                          return Switch(
                            value: autoSaveProvider.isAutoSaveEnabled,
                            onChanged: (value) {
                              autoSaveProvider.setAutoSaveEnabled(value);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value
                                      ? 'Auto-save enabled'
                                      : 'Auto-save disabled'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: value
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                ),
                              );
                            },
                            activeColor: AppTheme.primaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                if (isLargeScreen) ...[
                  const Divider(height: 1),
                  // Keyboard shortcuts setting (desktop only)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.keyboard,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keyboard Shortcuts',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View keyboard shortcuts for efficient editing',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _showKeyboardShortcutsDialog(context),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, bool isLargeScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App logo/icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.description,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // App name and version
          const Text(
            'Docu - text editor',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),

          // App description
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About This App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DOCU is a modern word processor created with Flutter. It provides professional document editing capabilities with a clean, intuitive interface.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Features:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                      'Rich text formatting with intuitive controls'),
                  _buildFeatureItem('Document organization and management'),
                  _buildFeatureItem('Real-time word count and page estimation'),
                  _buildFeatureItem('Automatic document saving'),
                  _buildFeatureItem('Responsive design for all screen sizes'),
                  if (isLargeScreen)
                    _buildFeatureItem(
                        'Keyboard shortcuts for efficient editing'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Adaptive experience note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.devices, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Adaptive Experience',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app adapts its interface based on your device type, providing an optimized experience for both mobile and desktop users.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              size: 16, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Show keyboard shortcuts dialog for desktop users
  void _showKeyboardShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShortcutRow(shortcut: 'B', description: 'Bold text'),
              _ShortcutRow(shortcut: 'I', description: 'Italic text'),
              _ShortcutRow(shortcut: 'U', description: 'Underline text'),
              _ShortcutRow(shortcut: 'Z', description: 'Undo'),
              _ShortcutRow(shortcut: 'Y', description: 'Redo'),
              _ShortcutRow(shortcut: '1', description: 'Heading 1'),
              _ShortcutRow(shortcut: '2', description: 'Heading 2'),
              _ShortcutRow(shortcut: '3', description: 'Heading 3'),
              _ShortcutRow(shortcut: 'L', description: 'Align left'),
              _ShortcutRow(shortcut: 'E', description: 'Align center'),
              _ShortcutRow(shortcut: 'R', description: 'Align right'),
              _ShortcutRow(shortcut: 'J', description: 'Justify text'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

// Helper widget for displaying keyboard shortcuts in the dialog
class _ShortcutRow extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutRow(
      {Key? key, required this.shortcut, required this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}
