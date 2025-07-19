import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Analyzing Qwen RAG Coverage...');
  
  try {
    final knowledgeFile = File('assets/medical_knowledge_rag.json');
    final content = await knowledgeFile.readAsString();
    final data = jsonDecode(content);
    
    if (data is Map && data.containsKey('knowledge_base')) {
      final entries = data['knowledge_base'] as List;
      print('📊 Total entries: ${entries.length}');
      
      // Analyze priorities
      final priorities = <String, int>{};
      final keywords = <String, int>{};
      
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final priority = entry['priority']?.toString() ?? 'unknown';
          priorities[priority] = (priorities[priority] ?? 0) + 1;
          
          // Count keywords
          final entryKeywords = entry['keywords'] as List?;
          if (entryKeywords != null) {
            for (final keyword in entryKeywords) {
              final keywordStr = keyword.toString();
              keywords[keywordStr] = (keywords[keywordStr] ?? 0) + 1;
            }
          }
        }
      }
      
      print('\n⚡ Priority Distribution:');
      priorities.forEach((priority, count) {
        final percentage = (count / entries.length * 100).toStringAsFixed(1);
        print('  - $priority: $count entries ($percentage%)');
      });
      
      print('\n🏷️ Top Keywords (Medical Topics):');
      final sortedKeywords = keywords.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (int i = 0; i < 20 && i < sortedKeywords.length; i++) {
        final keyword = sortedKeywords[i];
        print('  ${i + 1}. ${keyword.key}: ${keyword.value} entries');
      }
      
      // Detailed topic coverage analysis
      print('\n🏥 Detailed Medical Topic Coverage:');
      final medicalTopics = {
        'bleeding': ['bleeding', 'hemorrhage', 'haemorrhage'],
        'wounds': ['wound', 'cut', 'laceration', 'injury'],
        'pain': ['pain', 'analgesic', 'morphine'],
        'breathing': ['breathing', 'airway', 'respiratory', 'oxygen'],
        'heart': ['heart', 'cardiac', 'cardiovascular'],
        'infection': ['infection', 'sepsis', 'antibiotic'],
        'fever': ['fever', 'temperature', 'pyrexia'],
        'fractures': ['fracture', 'broken', 'bone'],
        'burns': ['burn', 'thermal', 'scald'],
        'shock': ['shock', 'hypotension', 'circulation'],
        'emergency': ['emergency', 'urgent', 'critical'],
        'surgery': ['surgery', 'surgical', 'operation'],
        'anesthesia': ['anesthesia', 'anaesthesia', 'sedation'],
        'trauma': ['trauma', 'injury', 'accident'],
        'first_aid': ['first aid', 'immediate care', 'triage']
      };
      
      final contentLower = content.toLowerCase();
      
      for (final topic in medicalTopics.keys) {
        final terms = medicalTopics[topic]!;
        int totalMentions = 0;
        
        for (final term in terms) {
          totalMentions += RegExp(term, caseSensitive: false).allMatches(contentLower).length;
        }
        
        final status = totalMentions > 0 ? '✅' : '❌';
        print('  $status $topic: $totalMentions mentions');
      }
      
      // Test specific queries
      print('\n🔍 Query Coverage Test:');
      final testQueries = [
        'How to stop bleeding?',
        'كيف أوقف النزيف؟',
        'What to do for heart attack?',
        'Managing severe pain',
        'Emergency breathing problems',
        'How to treat burns?',
        'Broken bone first aid',
        'High fever treatment',
        'Wound cleaning procedure',
        'Signs of infection'
      ];
      
      for (final query in testQueries) {
        final keywords = extractQueryKeywords(query);
        final coverage = calculateQueryCoverage(keywords, contentLower);
        final status = coverage > 50 ? '✅' : coverage > 20 ? '⚠️' : '❌';
        print('  $status "$query" - Coverage: $coverage%');
      }
      
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n🏁 RAG Coverage Analysis Complete!');
}

List<String> extractQueryKeywords(String query) {
  final words = query.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList();
  
  return words.take(5).toList();
}

int calculateQueryCoverage(List<String> keywords, String content) {
  if (keywords.isEmpty) return 0;
  
  int matchedKeywords = 0;
  for (final keyword in keywords) {
    if (content.contains(keyword)) {
      matchedKeywords++;
    }
  }
  
  return ((matchedKeywords / keywords.length) * 100).round();
}