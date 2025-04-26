import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/export_service.dart';
import '../theme.dart';

class ExportDialog extends StatefulWidget {
  final DocumentModel document;

  const ExportDialog({Key? key, required this.document}) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.download, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('Export Document'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a format to export your document:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFormatOption(
              format: ExportFormat.pdf,
              icon: Icons.picture_as_pdf,
              title: 'PDF Document',
              description: 'Export as a PDF document',
            ),
            const Divider(height: 1),
            _buildFormatOption(
              format: ExportFormat.plainText,
              icon: Icons.text_fields,
              title: 'Plain Text',
              description: 'Export as plain text (.txt)',
            ),
            const Divider(height: 1),
            _buildFormatOption(
              format: ExportFormat.html,
              icon: Icons.code,
              title: 'HTML Document',
              description: 'Export as an HTML document',
            ),
            const Divider(height: 1),
            _buildFormatOption(
              format: ExportFormat.markdown,
              icon: Icons.text_format,
              title: 'Markdown',
              description: 'Export as Markdown (.md)',
            ),
            const SizedBox(height: 16),
            if (_selectedFormat == ExportFormat.pdf) ... [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PDF format maintains your document layout and is ideal for printing or sharing.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.preview),
                label: const Text('Preview PDF before exporting'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ExportService.previewPdf(context, widget.document);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _exporting ? null : () => _exportDocument(context),
          child: _exporting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Exporting...'),
                  ],
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOption({
    required ExportFormat format,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Radio<ExportFormat>(
              value: format,
              groupValue: _selectedFormat,
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDocument(BuildContext context) async {
    setState(() {
      _exporting = true;
    });

    try {
      final success = await ExportService.exportDocument(
        context,
        widget.document,
        _selectedFormat,
      );

      if (success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document exported successfully as ${_getFormatName(_selectedFormat)}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.plainText:
        return 'Plain Text';
      case ExportFormat.html:
        return 'HTML';
      case ExportFormat.markdown:
        return 'Markdown';
    }
  }
}