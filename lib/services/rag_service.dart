import 'dart:async';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../database/medical_database.dart';

class RAGService {
  final MedicalDatabase _database = MedicalDatabase();
  CactusLM? _model;
  bool _isInitialized = false;
  bool _embeddingsGenerated = false;

  // Progress tracking
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<double> get progressStream => _progressController.stream;

  Future<List<double>> embedding(String text) async {
    if (_model == null) {
      throw Exception('Model not loaded for embedding generation.');
    }
    return await _model!.embedding(text);
  }

  Future<void> addKnowledgeEntry(MedicalKnowledgeEntry entry) async {
    await _database.insertKnowledgeEntry(entry);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _updateStatus('Initializing medical database...');
      _updateProgress(0.1);
      await _database.initializeKnowledgeBase();

      _updateStatus('Loading Qwen3-0.6B model for Arabic medical assistance...');
      _updateProgress(0.2);
      
      try {
        // Get the full path to the Qwen3-0.6B model file
        final modelPath = await _getModelPath();
        _updateProgress(0.3);

        _updateStatus('Initializing Qwen3-0.6B model...');
        _model = await CactusLM.init(
          // Use Qwen3-0.6B model optimized for Arabic and low-spec devices
          modelUrl: modelPath,
          contextSize: 512, // Increased for better context
          gpuLayers: 0, // CPU-only for Gaza device compatibility
          threads: 2, // Reduced to prevent overload
          generateEmbeddings: true, // Enable embedding generation for RAG
          onProgress: (progress, statusText, isError) {
            _updateStatus('Qwen3-0.6B: $statusText');
            if (!isError && progress != null) {
              _updateProgress(0.3 + (progress * 0.4)); // 30-70% for model loading
            }
            if (isError) {
              print('Model loading error: $statusText');
            }
          },
        );
        
        _updateProgress(0.7);
        _updateStatus('Model loaded successfully!');
        
      } catch (modelError) {
        _updateStatus('Model loading failed: $modelError');
        print('Detailed model error: $modelError');
        throw Exception('Failed to load AI model: $modelError');
      }

      _updateStatus('Generating embeddings for knowledge base...');
      _updateProgress(0.8);
      await _generateEmbeddings();

      _isInitialized = true;
      _updateStatus('Gaza Medical RAG system ready!');
      _updateProgress(1.0);
      
      // Test the system with a simple query
      
    } catch (e) {
      _updateStatus('RAG initialization failed: $e');
      print('Full RAG initialization error: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _generateEmbeddings() async {
    if (_embeddingsGenerated || _model == null) return;

    final entriesWithoutEmbeddings =
        await _database.getEntriesWithoutEmbeddings();

    if (entriesWithoutEmbeddings.isEmpty) {
      _embeddingsGenerated = true;
      return;
    }

    _updateStatus(
      'Generating embeddings for ${entriesWithoutEmbeddings.length} entries...',
    );

    for (int i = 0; i < entriesWithoutEmbeddings.length; i++) {
      final entry = entriesWithoutEmbeddings[i];

      try {
        // Generate embedding for the text
        final embedding = await _model!.embedding(entry.text);

        // Store embedding in database
        await _database.updateEmbedding(entry.entryId, embedding);

        // Update progress
        final progress = (i + 1) / entriesWithoutEmbeddings.length;
        _updateProgress(progress * 0.8); // Reserve 20% for final setup

        if (i % 10 == 0) {
          _updateStatus(
            'Generated embeddings: ${i + 1}/${entriesWithoutEmbeddings.length}',
          );
        }
      } catch (e) {
        print('Error generating embedding for ${entry.entryId}: $e');
        // Continue with next entry
      }
    }

    _embeddingsGenerated = true;
    _updateStatus('Embeddings generation completed');
  }

  Future<RAGResponse> query(String userQuery) async {
    if (!_isInitialized || _model == null) {
      throw Exception('RAG service not initialized');
    }

    try {
      // Step 1: Generate embedding for user query
      final queryEmbedding = await _model!.embedding(userQuery);

      // Step 2: Retrieve relevant knowledge entries
      final relevantEntries = await _database.findSimilarEntries(
        queryEmbedding,
        limit: 3, // Top 3 most relevant entries
      );

      // Step 3: Fallback to keyword search if no embeddings available
      List<MedicalKnowledgeEntry> fallbackEntries = [];
      if (relevantEntries.isEmpty) {
        final keywords = _extractKeywords(userQuery);
        fallbackEntries = await _database.searchByKeywords(keywords);
      }

      final contextEntries =
          relevantEntries.isNotEmpty ? relevantEntries : fallbackEntries;

      // Step 4: Generate response using retrieved context
      final response = await _generateResponse(userQuery, contextEntries);

      return RAGResponse(
        query: userQuery,
        response: response,
        relevantEntries: contextEntries,
        usedEmbeddings: relevantEntries.isNotEmpty,
      );
    } catch (e) {
      return RAGResponse(
        query: userQuery,
        response:
            'I apologize, but I encountered an error processing your medical query. Please try rephrasing your question or consult a healthcare professional.',
        relevantEntries: [],
        usedEmbeddings: false,
        error: e.toString(),
      );
    }
  }

  Future<String> _generateResponse(
    String query,
    List<MedicalKnowledgeEntry> context,
  ) async {
    if (context.isEmpty) {
      final isArabic = _isArabicQuery(query);
      return isArabic
          ? 'عذراً، ليس لدي معلومات محددة حول استفسارك. يرجى استشارة أخصائي رعاية صحية للحصول على المشورة الطبية المناسبة.'
          : 'I don\'t have specific information about your query. Please consult a healthcare professional for proper medical advice.';
    }

    // Build context from retrieved entries
    final contextText = context
        .map((entry) {
          return '${entry.category.toUpperCase()}: ${entry.text}';
        })
        .join('\n\n');

    // Detect if query is in Arabic and create appropriate prompt
    final isArabic = _isArabicQuery(query);
    final prompt =
        isArabic
            ? _createArabicPrompt(query, contextText)
            : _createEnglishPrompt(query, contextText);

    try {
      final result = await _model!.completion(
        [ChatMessage(role: 'user', content: prompt)],
        maxTokens: 100, // Reduced for faster responses
        temperature: 0.1, // Very low temperature for consistency
      );

      String response = result.text.trim();

      // Add appropriate medical disclaimer
      if (isArabic) {
        response +=
            '\n\n⚠️ تنويه: هذه المعلومات لأغراض تعليمية فقط. استشر دائماً أخصائيي الرعاية الصحية المؤهلين للتشخيص والعلاج المناسب.';
      } else {
        response +=
            '\n\n⚠️ DISCLAIMER: This information is for educational purposes only. Always consult qualified healthcare professionals for proper diagnosis and treatment.';
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response: $e');
      }

      // Fallback to template-based response
      return _generateTemplateResponse(query, context);
    }
  }

  String _createArabicPrompt(String query, String contextText) {
    return '''مساعد طبي لغزة. أجب بالعربية:

السؤال: $query
المعلومات: $contextText

الإجابة:''';
  }

  String _createEnglishPrompt(String query, String contextText) {
    return '''You are a medical assistant providing healthcare guidance in resource-limited settings like Gaza. Use the following medical knowledge to answer the user's question accurately and safely.

MEDICAL CONTEXT:
$contextText

USER QUESTION: $query

INSTRUCTIONS:
- Provide practical medical advice based on the context above
- Consider limited medical resources in Gaza
- Include warning signs when to seek immediate help
- Be clear and concise
- Always emphasize consulting healthcare professionals when possible
- If the question is about an emergency, clearly state to seek immediate medical attention

RESPONSE:''';
  }

  bool _isArabicQuery(String query) {
    // Simple Arabic detection - check for Arabic characters
    final arabicRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    return arabicRegex.hasMatch(query);
  }

  String _generateTemplateResponse(
    String query,
    List<MedicalKnowledgeEntry> context,
  ) {
    if (context.isEmpty) {
      return 'I don\'t have specific information about your query. Please consult a healthcare professional.';
    }

    final entry = context.first;
    final isEmergency =
        entry.priority == 'critical' || _containsEmergencyKeywords(query);

    String response = '';

    if (isEmergency) {
      response += '🚨 MEDICAL EMERGENCY DETECTED 🚨\n';
      response +=
          'Seek immediate medical attention or call emergency services.\n\n';
    }

    response += 'Based on medical guidelines:\n\n';
    response += entry.text;

    if (entry.priority == 'critical' || entry.priority == 'high') {
      response += '\n\n⚠️ This condition requires prompt medical attention.';
    }

    response +=
        '\n\n⚠️ DISCLAIMER: This information is for educational purposes only. Always consult qualified healthcare professionals.';

    return response;
  }

  List<String> _extractKeywords(String query) {
    final words = query.toLowerCase().split(RegExp(r'\W+'));

    // Medical keywords to prioritize
    final medicalKeywords = [
      'fever',
      'pain',
      'bleeding',
      'wound',
      'cut',
      'burn',
      'cough',
      'breathing',
      'chest',
      'heart',
      'stomach',
      'diarrhea',
      'vomiting',
      'headache',
      'dizzy',
      'weak',
      'infection',
      'swelling',
      'rash',
      'emergency',
      'urgent',
    ];

    final keywords = <String>[];

    for (final word in words) {
      if (word.length > 2 &&
          (medicalKeywords.contains(word) || word.length > 4)) {
        keywords.add(word);
      }
    }

    return keywords.take(5).toList(); // Limit to 5 keywords
  }

  bool _containsEmergencyKeywords(String query) {
    final emergencyKeywords = [
      'emergency',
      'urgent',
      'severe',
      'critical',
      'chest pain',
      'difficulty breathing',
      'unconscious',
      'bleeding heavily',
      'heart attack',
      'stroke',
      'choking',
    ];

    final queryLower = query.toLowerCase();
    return emergencyKeywords.any((keyword) => queryLower.contains(keyword));
  }

  void _updateStatus(String status) {
    print('RAG Service: $status');
    _statusController.add(status);
  }

  void _updateProgress(double progress) {
    _progressController.add(progress);
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final categoryStats = await _database.getCategoryStats();
    final totalEntries = categoryStats.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final entriesWithEmbeddings = await _database.getEntriesWithEmbeddings();

    return {
      'initialized': _isInitialized,
      'embeddings_generated': _embeddingsGenerated,
      'total_entries': totalEntries,
      'entries_with_embeddings': entriesWithEmbeddings.length,
      'categories': categoryStats,
      'model_loaded': _model != null,
    };
  }

  Future<String> _getModelPath() async {
    try {
      _updateStatus('Loading Qwen3-0.6B Arabic medical model...');

      // Copy model from assets to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/Qwen3-0.6B-UD-Q4_K_XL.gguf');

      if (!await modelFile.exists()) {
        _updateStatus('Copying Qwen3-0.6B model from assets...');
        final assetData = await rootBundle.load(
          'assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf',
        );
        await modelFile.writeAsBytes(assetData.buffer.asUint8List());
        _updateStatus('Model copied successfully');
      }

      _updateStatus(
        'Using Qwen3-0.6B model optimized for Arabic medical assistance',
      );
      return modelFile.path;
    } catch (e) {
      _updateStatus('Model setup failed: $e');
      throw Exception('Failed to load Qwen3-0.6B model: $e');
    }
  }

  void dispose() {
    _model?.dispose();
    _database.close();
    _statusController.close();
    _progressController.close();
  }
}

class RAGResponse {
  final String query;
  final String response;
  final List<MedicalKnowledgeEntry> relevantEntries;
  final bool usedEmbeddings;
  final String? error;

  RAGResponse({
    required this.query,
    required this.response,
    required this.relevantEntries,
    required this.usedEmbeddings,
    this.error,
  });

  bool get hasError => error != null;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'response': response,
      'relevant_entries_count': relevantEntries.length,
      'used_embeddings': usedEmbeddings,
      'has_error': hasError,
      'error': error,
    };
  }
}
