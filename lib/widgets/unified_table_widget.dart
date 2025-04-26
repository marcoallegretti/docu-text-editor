import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:data_table_2/data_table_2.dart';
import '../theme.dart';

/// A unified table widget that combines basic and enhanced table functionality
class UnifiedTableWidget extends StatefulWidget {
  final quill.QuillController controller;

  const UnifiedTableWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<UnifiedTableWidget> createState() => _UnifiedTableWidgetState();
}

class _UnifiedTableWidgetState extends State<UnifiedTableWidget> {
  int _rows = 3;
  int _columns = 3;

  bool _includeHeaders = true;
  bool _enableStyling = true;

  // Controls for the number of rows and columns
  final TextEditingController _rowsController =
      TextEditingController(text: '3');
  final TextEditingController _columnsController =
      TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    _rowsController.addListener(_updateRowCount);
    _columnsController.addListener(_updateColumnCount);
  }

  @override
  void dispose() {
    _rowsController.removeListener(_updateRowCount);
    _columnsController.removeListener(_updateColumnCount);
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  void _updateRowCount() {
    if (_rowsController.text.isNotEmpty) {
      try {
        final value = int.parse(_rowsController.text);
        setState(() {
          _rows = value.clamp(1, 20); // Allow up to 20 rows
        });
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  void _updateColumnCount() {
    if (_columnsController.text.isNotEmpty) {
      try {
        final value = int.parse(_columnsController.text);
        setState(() {
          _columns = value.clamp(1, 10); // Allow up to 10 columns
        });
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  void _showTableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.table_chart, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Insert Table'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450,
            maxHeight: 550,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row and column inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rowsController,
                        decoration: const InputDecoration(
                          labelText: 'Rows',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _columnsController,
                        decoration: const InputDecoration(
                          labelText: 'Columns',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Table options
                Text(
                  'Table Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),

                // Include headers option
                CheckboxListTile(
                  value: _includeHeaders,
                  title: const Text('Include Headers'),
                  subtitle: const Text('Add a header row to the table'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      _includeHeaders = value ?? true;
                    });
                  },
                ),

                // Styling option
                CheckboxListTile(
                  value: _enableStyling,
                  title: const Text('Enable Styling'),
                  subtitle: const Text('Add borders and styling to the table'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      _enableStyling = value ?? true;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Table preview
                Text(
                  'Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Table preview with DataTable2
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          headingRowHeight: _includeHeaders ? 56 : 0,
                          headingRowColor: _includeHeaders
                              ? WidgetStateProperty.all(Colors.grey.shade100)
                              : null,
                          border: _enableStyling
                              ? TableBorder.all(
                                  color: Colors.grey.shade300, width: 1)
                              : null,
                          columns: List.generate(
                            _columns.clamp(1, 10),
                            (index) => DataColumn2(
                              label: Text(
                                'Header ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              size: ColumnSize.S,
                            ),
                          ),
                          rows: List.generate(
                            _rows.clamp(1, 5),
                            (rowIndex) => DataRow2(
                              cells: List.generate(
                                _columns.clamp(1, 10),
                                (colIndex) =>
                                    DataCell(Text('Cell ${colIndex + 1}')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _insertTable();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Insert Table'),
          ),
        ],
      ),
    );
  }

  void _insertTable() {
    // Get current cursor position
    final index = widget.controller.selection.baseOffset;

    // First insert a newline to ensure the table is on its own line
    widget.controller.document.insert(index, '\n');

    // Create table in HTML format for better display
    final buffer = StringBuffer();

    // Use HTML-style table formatting
    buffer.write('<table style="border-collapse: collapse; width: 100%;">');

    // If headers are included, add the header row
    if (_includeHeaders) {
      buffer.write('<thead>');
      buffer.write('<tr>');
      for (int j = 0; j < _columns; j++) {
        if (_enableStyling) {
          buffer.write(
              '<th style="border: 1px solid #dddddd; text-align: left; padding: 8px; background-color: #f2f2f2;">');
        } else {
          buffer.write('<th>');
        }
        buffer.write('Header ${j + 1}');
        buffer.write('</th>');
      }
      buffer.write('</tr>');
      buffer.write('</thead>');
    }

    // Add the table body
    buffer.write('<tbody>');
    final startRow =
        _includeHeaders ? 1 : 0; // Skip the header row if already included
    for (int i = startRow; i < _rows; i++) {
      buffer.write('<tr>');
      for (int j = 0; j < _columns; j++) {
        if (_enableStyling) {
          buffer.write(
              '<td style="border: 1px solid #dddddd; text-align: left; padding: 8px;">');
        } else {
          buffer.write('<td>');
        }
        buffer.write('Cell ${j + 1}');
        buffer.write('</td>');
      }
      buffer.write('</tr>');
    }
    buffer.write('</tbody>');
    buffer.write('</table>');

    // Also create a Markdown-style table as backup for compatibility
    final markdownBuffer = StringBuffer();
    markdownBuffer.write('\n');

    // Add header row if needed
    if (_includeHeaders) {
      markdownBuffer.write('|');
      for (int j = 0; j < _columns; j++) {
        markdownBuffer.write(' Header ${j + 1} |');
      }
      markdownBuffer.write('\n');
    }

    // Create separator row
    markdownBuffer.write('|');
    for (int j = 0; j < _columns; j++) {
      markdownBuffer.write(' ----- |');
    }
    markdownBuffer.write('\n');

    // Create data rows
    final startMarkdownRow =
        _includeHeaders ? 1 : 0; // Skip the header row if already included
    for (int i = startMarkdownRow; i < _rows; i++) {
      markdownBuffer.write('|');
      for (int j = 0; j < _columns; j++) {
        markdownBuffer.write(' Cell ${j + 1} |');
      }
      markdownBuffer.write('\n');
    }

    // Try to use HTML table first, if not supported by the editor, fall back to markdown
    try {
      // Insert the HTML table at the current cursor position
      widget.controller.document.insert(index + 1, buffer.toString());
    } catch (e) {
      // Fall back to Markdown table if HTML insertion fails
      widget.controller.document.insert(index + 1, markdownBuffer.toString());
    }

    // Add a newline after the table
    widget.controller.document
        .insert(index + 1 + buffer.toString().length, '\n');

    // Update the cursor position
    widget.controller.updateSelection(
      TextSelection.collapsed(offset: index + buffer.toString().length + 2),
      quill.ChangeSource.local,
    );

    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Table inserted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're inside a Dialog (as a content) or used as a toolbar button
    bool isInsideDialog = false;

    // Try to find dialog ancestor
    if (context.findAncestorWidgetOfExactType<AlertDialog>() != null ||
        context.findAncestorWidgetOfExactType<Dialog>() != null) {
      isInsideDialog = true;
    }

    if (isInsideDialog) {
      // If inside a dialog, show the table creator directly
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row and column inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Rows',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _columnsController,
                  decoration: const InputDecoration(
                    labelText: 'Columns',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table options
          Text(
            'Table Options',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),

          // Include headers option
          CheckboxListTile(
            value: _includeHeaders,
            title: const Text('Include Headers'),
            subtitle: const Text('Add a header row to the table'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (value) {
              setState(() {
                _includeHeaders = value ?? true;
              });
            },
          ),

          // Styling option
          CheckboxListTile(
            value: _enableStyling,
            title: const Text('Enable Styling'),
            subtitle: const Text('Add borders and styling to the table'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (value) {
              setState(() {
                _enableStyling = value ?? true;
              });
            },
          ),

          const SizedBox(height: 24),

          // Table preview
          Text(
            'Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // Table preview with DataTable2
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      headingRowHeight: _includeHeaders ? 56 : 0,
                      headingRowColor: _includeHeaders
                          ? WidgetStateProperty.all(Colors.grey.shade100)
                          : null,
                      border: _enableStyling
                          ? TableBorder.all(
                              color: Colors.grey.shade300, width: 1)
                          : null,
                      columns: List.generate(
                        _columns.clamp(1, 10),
                        (index) => DataColumn2(
                          label: Text(
                            'Header ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.S,
                        ),
                      ),
                      rows: List.generate(
                        _rows.clamp(1, 5),
                        (rowIndex) => DataRow2(
                          cells: List.generate(
                            _columns.clamp(1, 10),
                            (colIndex) =>
                                DataCell(Text('Cell ${colIndex + 1}')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Insert button
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _insertTable();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Insert Table'),
              ),
            ),
          ),
        ],
      );
    } else {
      // If used as a toolbar button, show just the icon button
      return IconButton(
        icon: const Icon(Icons.table_chart),
        tooltip: 'Insert Table',
        onPressed: _showTableDialog,
      );
    }
  }
}
