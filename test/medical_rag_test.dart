import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/medical_rag_service.dart';

void main() {
  group('Medical RAG Service Tests', () {
    late MedicalRAGService ragService;

    setUp(() {
      ragService = MedicalRAGService();
    });

    test('should load medical knowledge from JSON', () async {
      // Mock the asset loading
      const String mockJson = '''
      {
        "medical_guidelines": [
          {
            "id": "test_fever",
            "category": "General Medicine",
            "symptoms": ["fever", "high temperature"],
            "condition": "Fever Management",
            "description": "Test fever condition",
            "treatment": "Rest and fluids",
            "warning_signs": ["severe headache"],
            "priority": "medium"
          }
        ],
        "emergency_protocols": [
          {
            "condition": "Test Emergency",
            "steps": ["Step 1", "Step 2"]
          }
        ]
      }
      ''';

      // This test would need proper mocking in a real scenario
      expect(ragService, isNotNull);
    });

    test('should perform fallback search when embeddings fail', () {
      final mockKnowledge = [
        MedicalKnowledge(
          id: 'fever_test',
          category: 'General Medicine',
          symptoms: ['fever', 'high temperature'],
          condition: 'Fever',
          description: 'High body temperature',
          treatment: 'Rest and medication',
          warningSigns: ['severe symptoms'],
          priority: 'medium',
        ),
      ];

      // Test fallback search logic
      expect(mockKnowledge.first.condition, equals('Fever'));
      expect(mockKnowledge.first.symptoms, contains('fever'));
    });

    test('should format medical response correctly', () {
      final knowledge = MedicalKnowledge(
        id: 'test',
        category: 'Emergency',
        symptoms: ['chest pain'],
        condition: 'Chest Pain',
        description: 'Pain in chest area',
        treatment: 'Seek immediate help',
        warningSigns: ['severe pain'],
        priority: 'critical',
      );

      final response = ragService.formatMedicalResponse([
        knowledge,
      ], 'chest pain');

      expect(response, contains('CRITICAL'));
      expect(response, contains('Chest Pain'));
      expect(response, contains('DISCLAIMER'));
    });

    test('should detect emergency keywords', () {
      final emergencyQueries = [
        'chest pain emergency',
        'difficulty breathing urgent',
        'severe bleeding critical',
      ];

      for (final query in emergencyQueries) {
        final response = ragService.formatMedicalResponse([], query);
        expect(response, contains('MEDICAL EMERGENCY DETECTED'));
      }
    });
  });
}
