import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🔍 Debugging RAG Knowledge Base...');
  
  // Test 1: Check medical knowledge base content
  print('\n📚 Test 1: Medical Knowledge Base Analysis');
  try {
    final knowledgeFile = File('assets/medical_knowledge_rag.json');
    if (await knowledgeFile.exists()) {
      final content = await knowledgeFile.readAsString();
      final data = jsonDecode(content);
      
      print('✅ Knowledge base loaded: ${content.length} characters');
      
      if (data is List) {
        print('📊 Total entries: ${data.length}');
        
        // Analyze categories
        final categories = <String, int>{};
        final priorities = <String, int>{};
        final sources = <String, int>{};
        
        for (final entry in data) {
          if (entry is Map<String, dynamic>) {
            final category = entry['category']?.toString() ?? 'unknown';
            final priority = entry['priority']?.toString() ?? 'unknown';
            final source = entry['source']?.toString() ?? 'unknown';
            
            categories[category] = (categories[category] ?? 0) + 1;
            priorities[priority] = (priorities[priority] ?? 0) + 1;
            sources[source] = (sources[source] ?? 0) + 1;
          }
        }
        
        print('\n📋 Categories:');
        categories.forEach((category, count) {
          print('  - $category: $count entries');
        });
        
        print('\n⚡ Priorities:');
        priorities.forEach((priority, count) {
          print('  - $priority: $count entries');
        });
        
        print('\n📖 Sources:');
        sources.forEach((source, count) {
          print('  - $source: $count entries');
        });
        
        // Sample some entries
        print('\n📝 Sample entries:');
        for (int i = 0; i < 3 && i < data.length; i++) {
          final entry = data[i];
          if (entry is Map<String, dynamic>) {
            print('Entry ${i + 1}:');
            print('  Category: ${entry['category']}');
            print('  Priority: ${entry['priority']}');
            print('  Text: ${entry['text']?.toString().substring(0, 100)}...');
            print('  Keywords: ${entry['keywords']}');
            print('');
          }
        }
        
      } else {
        print('⚠️ Knowledge base is not a list format');
      }
    } else {
      print('❌ Knowledge base file not found');
    }
  } catch (e) {
    print('❌ Error analyzing knowledge base: $e');
  }
  
  // Test 2: Test keyword matching
  print('\n🔍 Test 2: Keyword Matching Simulation');
  final testQueries = [
    'How to stop bleeding?',
    'كيف أوقف النزيف؟',
    'Recognizing heart attack symptoms',
    'Managing severe pain naturally',
    'What to do for high fever?',
    'Emergency breathing difficulties',
  ];
  
  for (final query in testQueries) {
    print('\nQuery: "$query"');
    
    // Simulate keyword extraction
    final keywords = extractKeywords(query);
    print('  Extracted keywords: $keywords');
    
    // Simulate Arabic detection
    final isArabic = detectArabic(query);
    print('  Arabic detected: $isArabic');
    
    // Check if we have relevant knowledge
    final relevantTopics = findRelevantTopics(keywords);
    print('  Relevant topics: $relevantTopics');
  }
  
  // Test 3: Check for common medical topics
  print('\n🏥 Test 3: Coverage Analysis');
  final commonTopics = [
    'bleeding', 'wound', 'fever', 'pain', 'heart attack', 'breathing',
    'emergency', 'first aid', 'infection', 'burn', 'fracture', 'diarrhea'
  ];
  
  try {
    final knowledgeFile = File('assets/medical_knowledge_rag.json');
    final content = await knowledgeFile.readAsString();
    
    print('Coverage check:');
    for (final topic in commonTopics) {
      final hasContent = content.toLowerCase().contains(topic);
      final status = hasContent ? '✅' : '❌';
      print('  $status $topic');
    }
  } catch (e) {
    print('❌ Error checking coverage: $e');
  }
  
  print('\n🏁 RAG Debug Analysis Complete!');
}

List<String> extractKeywords(String query) {
  final words = query.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList();
  
  // Medical keywords to prioritize
  final medicalKeywords = [
    'bleeding', 'pain', 'fever', 'wound', 'heart', 'breathing',
    'emergency', 'severe', 'attack', 'symptoms', 'treatment'
  ];
  
  final keywords = <String>[];
  for (final word in words) {
    if (medicalKeywords.contains(word) || word.length > 4) {
      keywords.add(word);
    }
  }
  
  return keywords.take(5).toList();
}

bool detectArabic(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');
  return arabicRegex.hasMatch(text);
}

List<String> findRelevantTopics(List<String> keywords) {
  final topicMap = {
    'bleeding': ['hemorrhage', 'wound care', 'first aid'],
    'pain': ['pain management', 'analgesics', 'comfort care'],
    'fever': ['temperature', 'infection', 'cooling'],
    'heart': ['cardiac', 'chest pain', 'cardiovascular'],
    'breathing': ['respiratory', 'airway', 'oxygen'],
    'emergency': ['trauma', 'critical care', 'urgent'],
  };
  
  final relevantTopics = <String>[];
  for (final keyword in keywords) {
    if (topicMap.containsKey(keyword)) {
      relevantTopics.addAll(topicMap[keyword]!);
    }
  }
  
  return relevantTopics.toSet().toList();
}