import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class VisualTableWidget extends StatefulWidget {
  final quill.QuillController controller;

  const VisualTableWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<VisualTableWidget> createState() => _VisualTableWidgetState();
}

class _VisualTableWidgetState extends State<VisualTableWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}