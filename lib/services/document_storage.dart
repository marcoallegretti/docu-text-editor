import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';

class DocumentStorage {
  static const String _documentsKey = 'text_editor_documents';
  static const String _recentDocumentKey = 'text_editor_recent_document';

  // Save all documents
  Future<void> saveDocuments(List<DocumentModel> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = documents.map((doc) => jsonEncode(doc.toMap())).toList();
    await prefs.setStringList(_documentsKey, documentsJson);
  }

  // Get all documents
  Future<List<DocumentModel>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = prefs.getStringList(_documentsKey) ?? [];
    return documentsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DocumentModel.fromMap(map);
    }).toList();
  }

  // Save a single document
  Future<void> saveDocument(DocumentModel document) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == document.id);
    
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    
    await saveDocuments(documents);
    await saveRecentDocument(document.id);
  }

  // Get a document by ID
  Future<DocumentModel?> getDocument(String id) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == id);
    
    if (index >= 0) {
      return documents[index];
    }
    return null;
  }

  // Delete a document
  Future<void> deleteDocument(String id) async {
    final documents = await getDocuments();
    documents.removeWhere((doc) => doc.id == id);
    await saveDocuments(documents);
    
    final recentId = await getRecentDocumentId();
    if (recentId == id) {
      await clearRecentDocument();
    }
  }

  // Save the ID of the most recently accessed document
  Future<void> saveRecentDocument(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentDocumentKey, id);
  }

  // Get the most recently accessed document ID
  Future<String?> getRecentDocumentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recentDocumentKey);
  }

  // Clear the recent document reference
  Future<void> clearRecentDocument() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentDocumentKey);
  }

  // Get the most recent document, or create a new one
  Future<DocumentModel> getRecentOrNewDocument() async {
    final recentId = await getRecentDocumentId();
    
    if (recentId != null) {
      final document = await getDocument(recentId);
      if (document != null) {
        return document;
      }
    }
    
    // No recent document found, create a new one
    final newDocument = DocumentModel.empty();
    await saveDocument(newDocument);
    return newDocument;
  }
}