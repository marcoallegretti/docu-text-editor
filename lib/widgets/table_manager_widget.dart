import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme.dart';

class TableManagerWidget extends StatefulWidget {
  final quill.QuillController controller;

  const TableManagerWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<TableManagerWidget> createState() => _TableManagerWidgetState();
}

class _TableManagerWidgetState extends State<TableManagerWidget> {
  int _rows = 3;
  int _columns = 3;
  bool _showTableCreator = false;

  // Controls for the number of rows and columns
  final TextEditingController _rowsController = TextEditingController(text: '3');
  final TextEditingController _columnsController = TextEditingController(text: '3');

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
          _rows = value.clamp(1, 10);
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
          _columns = value.clamp(1, 10);
        });
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  void _insertTable() {
    // Close the dialog first
    setState(() {
      _showTableCreator = false;
    });

    // Skip HTML approach and use the Markdown-style text table instead
    _insertBasicTable();
    return;
    // This entire HTML-based method has been replaced by _insertBasicTable()
    // which creates a Markdown-style text table that displays better in QuillEditor
  }

  void _insertBasicTable() {
    // Create a properly formatted Markdown-style table
    final buffer = StringBuffer();
    buffer.write('\n');

    // Create header row with column markers
    buffer.write('|');
    for (int j = 0; j < _columns; j++) {
      buffer.write(' Header ${j+1} |');
    }
    buffer.write('\n');

    // Create separator row
    buffer.write('|');
    for (int j = 0; j < _columns; j++) {
      buffer.write(' ----- |');
    }
    buffer.write('\n');

    // Create data rows
    for (int i = 1; i < _rows; i++) { // Start from 1 as row 0 is header
      buffer.write('|');
      for (int j = 0; j < _columns; j++) {
        buffer.write(' Cell ${j+1} |');
      }
      buffer.write('\n');
    }

    // Insert the text at the current cursor position
    final index = widget.controller.selection.baseOffset;
    widget.controller.document.insert(index, buffer.toString());
    
    // Update the cursor position
    widget.controller.updateSelection(
      TextSelection.collapsed(offset: index + buffer.toString().length),
      quill.ChangeSource.local,
    );
    
    // Show helpful message to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Table inserted as Markdown format. Edit the cell contents as needed.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.table_chart),
          tooltip: 'Insert Table',
          onPressed: () {
            setState(() {
              _showTableCreator = !_showTableCreator;
            });
          },
        ),
        if (_showTableCreator)
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Insert Table',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interactive table preview
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                        maxHeight: 220,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columns > 5 ? 5 : _columns,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _rows > 5 ? 5 * 5 : _rows * _columns,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.grey.shade50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              if (newValue.text.isEmpty) {
                                return newValue;
                              }
                              int? value = int.tryParse(newValue.text);
                              if (value == null) {
                                return oldValue;
                              }
                              if (value < 1) value = 1;
                              if (value > 10) value = 10;
                              return TextEditingValue(
                                text: value.toString(),
                                selection: newValue.selection,
                              );
                            }),
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
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              if (newValue.text.isEmpty) {
                                return newValue;
                              }
                              int? value = int.tryParse(newValue.text);
                              if (value == null) {
                                return oldValue;
                              }
                              if (value < 1) value = 1;
                              if (value > 10) value = 10;
                              return TextEditingValue(
                                text: value.toString(),
                                selection: newValue.selection,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showTableCreator = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _insertTable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Insert Table'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TableEditorWidget extends StatelessWidget {
  final quill.QuillController controller;

  const TableEditorWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Table Options',
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'add_row',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Add Row'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_column',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Add Column'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete_row',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete Row'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete_column',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete Column'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'format_cell',
          child: Row(
            children: [
              Icon(Icons.format_color_fill, size: 18),
              SizedBox(width: 8),
              Text('Format Cell'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'merge_cells',
          child: Row(
            children: [
              Icon(Icons.call_merge, size: 18),
              SizedBox(width: 8),
              Text('Merge Cells'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete_table',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Table', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        // Implement table editing actions based on selection
        // For now, we'll just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table action: $value'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}