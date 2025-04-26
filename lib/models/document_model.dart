import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class DocumentModel {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  String content; // JSON string of QuillDelta
  int wordCount;
  int pageCount;

  DocumentModel({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.content,
    this.wordCount = 0,
    this.pageCount = 1,
  })
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
      updatedAt = updatedAt ?? DateTime.now();

  // Convert Document to QuillController
  quill.QuillController toQuillController() {
    try {
      print('toQuillController: Decoding content: ' + content);
      final delta = jsonDecode(content);
      print('toQuillController: Decoded delta: ' + delta.toString());
      final document = quill.Document.fromJson(delta);
      print('toQuillController: Document length: ' + document.length.toString());
      // Create a new controller with our document
      return quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        // Ensure proper rendering of styles
        keepStyleOnNewLine: true,
      );
    } catch (e) {
      print('Error creating QuillController: $e');
      // If there's an error, create a new document
      return quill.QuillController.basic();
    }
  }

  // Update content from QuillController
  void updateContent(quill.QuillController controller) {
    final json = jsonEncode(controller.document.toDelta().toJson());
    content = json;
    updatedAt = DateTime.now();
    _updateWordCount(controller.document.toPlainText());
    _updatePageCount(controller.document.toPlainText());
  }

  // Calculate word count from plain text
  void _updateWordCount(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    wordCount = words.where((word) => word.isNotEmpty).length;
  }

  // Estimate page count (roughly 250 words per page)
  void _updatePageCount(String text) {
    final estimatedPages = (wordCount / 250).ceil();
    pageCount = estimatedPages > 0 ? estimatedPages : 1;
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'content': content,
      'wordCount': wordCount,
      'pageCount': pageCount,
    };
  }

  // Create from Map
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      content: map['content'],
      wordCount: map['wordCount'],
      pageCount: map['pageCount'],
    );
  }

  // Create new empty document
  factory DocumentModel.empty() {
    final controller = quill.QuillController.basic();
    return DocumentModel(
      title: 'Untitled Document',
      content: jsonEncode(controller.document.toDelta().toJson()),
      wordCount: 0,
      pageCount: 1,
    );
  }
}