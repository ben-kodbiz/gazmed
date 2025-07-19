import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cactus/cactus.dart';

class MedicalKnowledge {
  final String id;
  final String category;
  final List<String> symptoms;
  final String condition;
  final String description;
  final String treatment;
  final List<String> warningSigns;
  final String priority;

  MedicalKnowledge({
    required this.id,
    required this.category,
    required this.symptoms,
    required this.condition,
    required this.description,
    required this.treatment,
    required this.warningSigns,
    required this.priority,
  });

  factory MedicalKnowledge.fromJson(Map<String, dynamic> json) {
    return MedicalKnowledge(
      id: json['id'],
      category: json['category'],
      symptoms: List<String>.from(json['symptoms']),
      condition: json['condition'],
      description: json['description'],
      treatment: json['treatment'],
      warningSigns: List<String>.from(json['warning_signs']),
      priority: json['priority'],
    );
  }

  String get searchableText =>
      '${symptoms.join(' ')} $condition $description $treatment ${warningSigns.join(' ')}';
}

class EmergencyProtocol {
  final String condition;
  final List<String> steps;

  EmergencyProtocol({required this.condition, required this.steps});

  factory EmergencyProtocol.fromJson(Map<String, dynamic> json) {
    return EmergencyProtocol(
      condition: json['condition'],
      steps: List<String>.from(json['steps']),
    );
  }
}

class MedicalRAGService {
  List<MedicalKnowledge> _knowledgeBase = [];
  List<EmergencyProtocol> _emergencyProtocols = [];
  Map<String, List<double>> _embeddings = {};
  CactusLM? _model;

  Future<void> initialize(CactusLM model) async {
    _model = model;
    await _loadMedicalKnowledge();
    await _generateEmbeddings();
  }

  Future<void> _loadMedicalKnowledge() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/medical_knowledge.json',
      );
      final data = json.decode(jsonString);

      _knowledgeBase =
          (data['medical_guidelines'] as List)
              .map((item) => MedicalKnowledge.fromJson(item))
              .toList();

      _emergencyProtocols =
          (data['emergency_protocols'] as List)
              .map((item) => EmergencyProtocol.fromJson(item))
              .toList();
    } catch (e) {
      print('Error loading medical knowledge: $e');
    }
  }

  Future<void> _generateEmbeddings() async {
    if (_model == null) return;

    for (final knowledge in _knowledgeBase) {
      try {
        final embedding = await _model!.embedding(knowledge.searchableText);
        _embeddings[knowledge.id] = embedding;
      } catch (e) {
        print('Error generating embedding for ${knowledge.id}: $e');
      }
    }
  }

  Future<List<MedicalKnowledge>> retrieveRelevantKnowledge(String query) async {
    if (_model == null || _embeddings.isEmpty) return [];

    try {
      final queryEmbedding = await _model!.embedding(query.toLowerCase());
      final similarities = <String, double>{};

      for (final entry in _embeddings.entries) {
        final similarity = _cosineSimilarity(queryEmbedding, entry.value);
        similarities[entry.key] = similarity;
      }

      // Sort by similarity and take top 3
      final sortedIds =
          similarities.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final relevantKnowledge = <MedicalKnowledge>[];
      for (final entry in sortedIds.take(3)) {
        final knowledge = _knowledgeBase.firstWhere((k) => k.id == entry.key);
        relevantKnowledge.add(knowledge);
      }

      return relevantKnowledge;
    } catch (e) {
      print('Error retrieving relevant knowledge: $e');
      return _fallbackSearch(query);
    }
  }

  List<MedicalKnowledge> _fallbackSearch(String query) {
    final queryLower = query.toLowerCase();
    final matches = <MedicalKnowledge>[];

    for (final knowledge in _knowledgeBase) {
      if (knowledge.symptoms.any((s) => queryLower.contains(s.toLowerCase())) ||
          knowledge.condition.toLowerCase().contains(queryLower) ||
          knowledge.description.toLowerCase().contains(queryLower)) {
        matches.add(knowledge);
      }
    }

    // Sort by priority (critical > high > medium > low)
    matches.sort((a, b) {
      const priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      return (priorityOrder[a.priority] ?? 4).compareTo(
        priorityOrder[b.priority] ?? 4,
      );
    });

    return matches.take(3).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  String formatMedicalResponse(
    List<MedicalKnowledge> relevantKnowledge,
    String originalQuery,
  ) {
    final buffer = StringBuffer();

    // Check for emergency keywords
    final emergencyKeywords = [
      'emergency',
      'urgent',
      'severe',
      'critical',
      'chest pain',
      'difficulty breathing',
      'unconscious',
    ];
    final isEmergency = emergencyKeywords.any(
      (keyword) => originalQuery.toLowerCase().contains(keyword),
    );

    if (isEmergency) {
      buffer.writeln("⚠️ MEDICAL EMERGENCY DETECTED ⚠️");
      buffer.writeln(
        "Seek immediate medical attention or call emergency services.\n",
      );
    }

    if (relevantKnowledge.isEmpty) {
      if (isEmergency) {
        buffer.writeln(
          "No specific medical information found, but this appears to be an emergency situation.",
        );
      } else {
        buffer.writeln(
          "I couldn't find specific medical information for your query.",
        );
      }
      buffer.writeln(
        "Please consult a healthcare professional for proper diagnosis and treatment.",
      );
      return buffer.toString();
    }

    for (int i = 0; i < relevantKnowledge.length; i++) {
      final knowledge = relevantKnowledge[i];

      if (knowledge.priority == 'critical') {
        buffer.writeln("🚨 CRITICAL: ${knowledge.condition}");
      } else if (knowledge.priority == 'high') {
        buffer.writeln("⚠️ HIGH PRIORITY: ${knowledge.condition}");
      } else {
        buffer.writeln("📋 ${knowledge.condition}");
      }

      buffer.writeln("Description: ${knowledge.description}");
      buffer.writeln("Treatment: ${knowledge.treatment}");

      if (knowledge.warningSigns.isNotEmpty) {
        buffer.writeln(
          "⚠️ Warning Signs: ${knowledge.warningSigns.join(', ')}",
        );
      }

      if (i < relevantKnowledge.length - 1) {
        buffer.writeln("---");
      }
    }

    buffer.writeln(
      "\n⚠️ DISCLAIMER: This is general medical information only. Always consult qualified healthcare professionals for proper diagnosis and treatment.",
    );

    return buffer.toString();
  }

  List<EmergencyProtocol> getEmergencyProtocols() => _emergencyProtocols;
}
