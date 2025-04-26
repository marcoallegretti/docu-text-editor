import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:data_table_2/data_table_2.dart';
import '../theme.dart';

class EnhancedTableWidget extends StatefulWidget {
  final quill.QuillController controller;

  const EnhancedTableWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<EnhancedTableWidget> createState() => _EnhancedTableWidgetState();
}

class _EnhancedTableWidgetState extends State<EnhancedTableWidget> {
  int _rows = 3;
  int _columns = 3;
  bool _showTableCreator = false;
  bool _includeHeaders = true;
  bool _enableSorting = false;
  bool _enablePagination = false;
  bool _enableSearching = false;
  int _rowsPerPage = 10;

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
          _rows = value.clamp(1, 50); // Allow more rows since we support pagination
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

  // Insert both a markdown-style table for compatibility and storage
  // but also insert a special delimiter that will be used to render an enhanced
  // table when viewing
  void _insertEnhancedTable() {
    // Get current cursor position
    final index = widget.controller.selection.baseOffset;
    
    // First insert a newline to ensure the table is on its own line
    widget.controller.document.insert(index, '\n');
    
    // Generate a table configuration for our enhanced table
    final tableConfig = {
      'rows': _rows,
      'columns': _columns,
      'headers': _includeHeaders,
      'sorting': _enableSorting,
      'pagination': _enablePagination,
      'searching': _enableSearching,
      'rowsPerPage': _rowsPerPage,
    };
    
    // Create a placeholder for our enhanced table with the configuration
    // We'll use special delimiters that can be detected when rendering
    final enhancedTablePlaceholder = "\n<!-- ENHANCED_TABLE_BEGIN\n${tableConfig.toString()}\nENHANCED_TABLE_END -->\n";
    
    // Also create a Markdown-style table as fallback for compatibility
    final buffer = StringBuffer();
    
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
    
    // Insert both the enhanced table placeholder and the markdown fallback
    widget.controller.document.insert(index + 1, enhancedTablePlaceholder + buffer.toString());
    
    // Add a newline after the table
    widget.controller.document.insert(index + 1 + enhancedTablePlaceholder.length + buffer.toString().length, '\n');
    
    // Update the cursor position
    widget.controller.updateSelection(
      TextSelection.collapsed(offset: index + enhancedTablePlaceholder.length + buffer.toString().length + 2),
      quill.ChangeSource.local,
    );
    
    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enhanced table inserted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
    
    setState(() {
      _showTableCreator = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.table_chart),
          tooltip: 'Insert Enhanced Table',
          onPressed: () {
            setState(() {
              _showTableCreator = !_showTableCreator;
            });
          },
        ),
        if (_showTableCreator)
          Positioned(
            top: 40,
            left: 0,
            child: Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Insert Enhanced Table',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
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
                    const SizedBox(height: 16),
                    
                    // Interactive table preview
                    Text(
                      'Table Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 600,
                          columns: List.generate(_columns.clamp(1, 5), (index) => 
                            DataColumn2(
                              label: Text('Header ${index + 1}'),
                              size: ColumnSize.S,
                            ),
                          ),
                          rows: List.generate(_rows.clamp(1, 5), (rowIndex) => 
                            DataRow2(
                              cells: List.generate(_columns.clamp(1, 5), (colIndex) => 
                                DataCell(Text('Cell ${colIndex + 1}')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Table options
                    Text(
                      'Table Options',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _includeHeaders,
                      title: const Text('Include Headers'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (value) {
                        setState(() {
                          _includeHeaders = value ?? true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: _enableSorting,
                      title: const Text('Enable Sorting'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (value) {
                        setState(() {
                          _enableSorting = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: _enablePagination,
                      title: const Text('Enable Pagination'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (value) {
                        setState(() {
                          _enablePagination = value ?? false;
                        });
                      },
                    ),
                    if (_enablePagination)
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: Row(
                          children: [
                            const Text('Rows per page:'),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _rowsPerPage,
                              items: [5, 10, 15, 20, 25, 50].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value'),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _rowsPerPage = newValue;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    CheckboxListTile(
                      value: _enableSearching,
                      title: const Text('Enable Searching'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (value) {
                        setState(() {
                          _enableSearching = value ?? false;
                        });
                      },
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
                          onPressed: _insertEnhancedTable,
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
          ),
      ],
    );
  }
}

// Renderer component for the enhanced table
class EnhancedTableRenderer extends StatefulWidget {
  final Map<String, dynamic> tableConfig;
  final List<List<String>> initialData;

  const EnhancedTableRenderer({
    Key? key,
    required this.tableConfig,
    required this.initialData,
  }) : super(key: key);

  @override
  State<EnhancedTableRenderer> createState() => _EnhancedTableRendererState();
}

class _EnhancedTableRendererState extends State<EnhancedTableRenderer> {
  late List<List<String>> _tableData;
  late int _page;
  late int _rowsPerPage;
  String _searchQuery = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tableData = List.from(widget.initialData);
    _page = 0;
    _rowsPerPage = widget.tableConfig['rowsPerPage'] ?? 10;
  }

  // Handle sorting
  void _sort<T>(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _tableData.sort((a, b) {
        if (!ascending) {
          final temp = a;
          a = b;
          b = temp;
        }
        return a[columnIndex].compareTo(b[columnIndex]);
      });
    });
  }

  // Filter data based on search query
  List<List<String>> get _filteredData {
    if (_searchQuery.isEmpty) {
      return _tableData;
    }

    return _tableData.where((row) {
      return row.any((cell) => 
        cell.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  // Get paginated data
  List<List<String>> get _paginatedData {
    if (!widget.tableConfig['pagination']) {
      return _filteredData;
    }

    final startIndex = _page * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    
    if (startIndex >= _filteredData.length) {
      return [];
    }
    
    return _filteredData.sublist(
      startIndex, 
      endIndex > _filteredData.length ? _filteredData.length : endIndex
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHeaders = widget.tableConfig['headers'] ?? true;
    final enableSorting = widget.tableConfig['sorting'] ?? false;
    final enablePagination = widget.tableConfig['pagination'] ?? false;
    final enableSearching = widget.tableConfig['searching'] ?? false;
    final columns = widget.tableConfig['columns'] ?? 3;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (enableSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _page = 0; // Reset to first page when searching
                  });
                },
              ),
            ),
          
          // Enhanced table with DataTable2
          SizedBox(
            width: double.infinity,
            child: enablePagination ? PaginatedDataTable2(
              columns: List.generate(columns, (index) {
                return DataColumn2(
                  label: Text(
                    hasHeaders && _tableData.isNotEmpty && _tableData[0].length > index
                      ? _tableData[0][index]
                      : 'Column ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Only enable sorting if configured
                  onSort: enableSorting ? (columnIndex, ascending) {
                    _sort(columnIndex, ascending);
                  } : null,
                );
              }),
              // Skip header row if hasHeaders is true
              source: _EnhancedTableDataSource(
                data: _paginatedData.sublist(hasHeaders ? 1 : 0),
                columns: columns,
              ),
              // Only show pagination controls if enabled
              rowsPerPage: enablePagination ? _rowsPerPage : _filteredData.length,
              showFirstLastButtons: enablePagination,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              empty: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text('No data available'),
                ),
              ),
            ) : DataTable2(
              columns: List.generate(columns, (index) {
                return DataColumn2(
                  label: Text(
                    hasHeaders && _tableData.isNotEmpty && _tableData[0].length > index
                      ? _tableData[0][index]
                      : 'Column ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Only enable sorting if configured
                  onSort: enableSorting ? (columnIndex, ascending) {
                    _sort(columnIndex, ascending);
                  } : null,
                );
              }),
              rows: _paginatedData.sublist(hasHeaders ? 1 : 0).map((row) {
                return DataRow2(
                  cells: List.generate(
                    columns, 
                    (cellIndex) => DataCell(
                      Text(cellIndex < row.length ? row[cellIndex] : ''),
                    ),
                  ),
                );
              }).toList(),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              empty: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No data available'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom data source for the DataTable2
class _EnhancedTableDataSource extends DataTableSource {
  final List<List<String>> data;
  final int columns;

  _EnhancedTableDataSource({
    required this.data,
    required this.columns,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    
    final row = data[index];
    return DataRow2(
      cells: List.generate(
        columns,
        (cellIndex) => DataCell(
          Text(cellIndex < row.length ? row[cellIndex] : ''),
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}