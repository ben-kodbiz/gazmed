import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class DocumentProcessor {
  static const int _maxChunkSize = 500; // Maximum characters per chunk
  static const int _chunkOverlap = 50;  // Overlap between chunks

  /// Extract text from various document types
  Future<String> extractText(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return await _extractFromPDF(file);
      case 'doc':
      case 'docx':
        return await _extractFromWord(file);
      case 'txt':
        return await _extractFromText(file);
      default:
        throw Exception('Unsupported file type: $extension');
    }
  }

  /// Extract text from PDF files
  Future<String> _extractFromPDF(File file) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from Word documents
  Future<String> _extractFromWord(File file) async {
    try {
      // For now, we'll use a simple approach
      // In production, you might want to use a more robust library
      // like docx_to_text or archive package
      
      // Simple fallback: try to read as text (works for some .doc files)
      final bytes = await file.readAsBytes();
      final text = String.fromCharCodes(bytes.where((byte) => byte >= 32 && byte <= 126));
      
      if (text.trim().isEmpty) {
        throw Exception('Could not extract readable text from Word document');
      }
      
      return _cleanExtractedText(text);
    } catch (e) {
      throw Exception('Failed to extract text from Word document: $e');
    }
  }

  /// Extract text from plain text files
  Future<String> _extractFromText(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read text file: $e');
    }
  }

  /// Clean extracted text by removing excessive whitespace and control characters
  String _cleanExtractedText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple whitespace with single space
        .replaceAll(RegExp(r'[^\x20-\x7E\u0600-\u06FF]'), '') // Keep printable ASCII and Arabic
        .trim();
  }

  /// Chunk text into manageable pieces for RAG processing
  Future<List<DocumentChunk>> chunkText(String text, {required String fileName}) async {
    final chunks = <DocumentChunk>[];
    final sentences = _splitIntoSentences(text);
    
    String currentChunk = '';
    int chunkIndex = 0;
    
    for (final sentence in sentences) {
      // If adding this sentence would exceed max chunk size, save current chunk
      if (currentChunk.length + sentence.length > _maxChunkSize && currentChunk.isNotEmpty) {
        chunks.add(DocumentChunk(
          id: '${fileName}_chunk_$chunkIndex',
          text: currentChunk.trim(),
          source: fileName,
          chunkIndex: chunkIndex,
          category: _detectCategory(currentChunk),
          priority: _detectPriority(currentChunk),
          keywords: _extractKeywords(currentChunk),
        ));
        
        // Start new chunk with overlap from previous chunk
        final words = currentChunk.split(' ');
        final overlapWords = words.length > 10 
            ? words.sublist(words.length - 10).join(' ')
            : '';
        
        currentChunk = overlapWords.isEmpty ? sentence : '$overlapWords $sentence';
        chunkIndex++;
      } else {
        currentChunk += currentChunk.isEmpty ? sentence : ' $sentence';
      }
    }
    
    // Add the last chunk if it has content
    if (currentChunk.trim().isNotEmpty) {
      chunks.add(DocumentChunk(
        id: '${fileName}_chunk_$chunkIndex',
        text: currentChunk.trim(),
        source: fileName,
        chunkIndex: chunkIndex,
        category: _detectCategory(currentChunk),
        priority: _detectPriority(currentChunk),
        keywords: _extractKeywords(currentChunk),
      ));
    }
    
    return chunks;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting - can be improved with more sophisticated NLP
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Detect medical category from text content
  String _detectCategory(String text) {
    final textLower = text.toLowerCase();
    
    final categoryKeywords = {
      'emergency': ['emergency', 'urgent', 'critical', 'life-threatening', 'immediate'],
      'surgery': ['surgery', 'surgical', 'operation', 'procedure', 'incision'],
      'trauma': ['trauma', 'injury', 'wound', 'fracture', 'bleeding'],
      'cardiology': ['heart', 'cardiac', 'cardiovascular', 'blood pressure'],
      'respiratory': ['breathing', 'lung', 'respiratory', 'airway', 'oxygen'],
      'infection': ['infection', 'bacteria', 'virus', 'antibiotic', 'sepsis'],
      'pain_management': ['pain', 'analgesic', 'morphine', 'relief'],
      'pediatric': ['child', 'children', 'pediatric', 'infant', 'baby'],
      'general': ['treatment', 'diagnosis', 'symptoms', 'medical'],
    };
    
    for (final category in categoryKeywords.keys) {
      final keywords = categoryKeywords[category]!;
      if (keywords.any((keyword) => textLower.contains(keyword))) {
        return category;
      }
    }
    
    return 'general';
  }

  /// Detect priority level from text content
  String _detectPriority(String text) {
    final textLower = text.toLowerCase();
    
    final criticalKeywords = ['emergency', 'critical', 'life-threatening', 'urgent', 'immediate', 'fatal'];
    final highKeywords = ['severe', 'serious', 'major', 'significant', 'important'];
    final lowKeywords = ['minor', 'mild', 'basic', 'simple', 'routine'];
    
    if (criticalKeywords.any((keyword) => textLower.contains(keyword))) {
      return 'critical';
    } else if (highKeywords.any((keyword) => textLower.contains(keyword))) {
      return 'high';
    } else if (lowKeywords.any((keyword) => textLower.contains(keyword))) {
      return 'low';
    }
    
    return 'medium';
  }

  /// Extract relevant keywords from text
  List<String> _extractKeywords(String text) {
    final textLower = text.toLowerCase();
    final words = textLower.split(RegExp(r'\W+'));
    
    final medicalKeywords = [
      'bleeding', 'wound', 'pain', 'fever', 'infection', 'surgery', 'treatment',
      'emergency', 'breathing', 'heart', 'blood', 'pressure', 'medication',
      'diagnosis', 'symptoms', 'therapy', 'care', 'patient', 'medical',
      'hospital', 'doctor', 'nurse', 'health', 'disease', 'condition'
    ];
    
    final keywords = <String>[];
    for (final word in words) {
      if (word.length > 3 && medicalKeywords.contains(word)) {
        keywords.add(word);
      }
    }
    
    // Remove duplicates and limit to top 5
    return keywords.toSet().take(5).toList();
  }

  /// Save document metadata to local storage
  Future<void> saveDocumentMetadata(File file, int chunkCount) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/uploaded_documents.json');
      
      List<Map<String, dynamic>> documents = [];
      
      // Load existing documents if file exists
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final data = jsonDecode(content) as List;
        documents = data.cast<Map<String, dynamic>>();
      }
      
      // Add new document
      final fileName = file.path.split('/').last;
      final fileType = fileName.split('.').last;
      
      documents.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fileName': fileName,
        'fileType': fileType,
        'chunkCount': chunkCount,
        'uploadDate': DateTime.now().toIso8601String(),
        'filePath': file.path,
      });
      
      // Save updated list
      await metadataFile.writeAsString(jsonEncode(documents));
    } catch (e) {
      throw Exception('Failed to save document metadata: $e');
    }
  }

  /// Get list of uploaded documents
  Future<List<UploadedDocument>> getUploadedDocuments() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/uploaded_documents.json');
      
      if (!await metadataFile.exists()) {
        return [];
      }
      
      final content = await metadataFile.readAsString();
      final data = jsonDecode(content) as List;
      
      return data.map((item) => UploadedDocument(
        id: item['id'],
        fileName: item['fileName'],
        fileType: item['fileType'],
        chunkCount: item['chunkCount'],
        uploadDate: DateTime.parse(item['uploadDate']),
      )).toList();
    } catch (e) {
      print('Error loading uploaded documents: $e');
      return [];
    }
  }

  /// Delete a document and its metadata
  Future<void> deleteDocument(String documentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/uploaded_documents.json');
      
      if (!await metadataFile.exists()) {
        return;
      }
      
      final content = await metadataFile.readAsString();
      final data = jsonDecode(content) as List;
      final documents = data.cast<Map<String, dynamic>>();
      
      // Remove document with matching ID
      documents.removeWhere((doc) => doc['id'] == documentId);
      
      // Save updated list
      await metadataFile.writeAsString(jsonEncode(documents));
    } catch (e) {
      throw Exception('Failed to delete document metadata: $e');
    }
  }
}

class DocumentChunk {
  final String id;
  final String text;
  final String source;
  final int chunkIndex;
  final String category;
  final String priority;
  final List<String> keywords;

  DocumentChunk({
    required this.id,
    required this.text,
    required this.source,
    required this.chunkIndex,
    required this.category,
    required this.priority,
    required this.keywords,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'source': source,
      'chunk_index': chunkIndex,
      'category': category,
      'priority': priority,
      'keywords': keywords,
    };
  }
}

class UploadedDocument {
  final String id;
  final String fileName;
  final String fileType;
  final int chunkCount;
  final DateTime uploadDate;

  UploadedDocument({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.chunkCount,
    required this.uploadDate,
  });
}