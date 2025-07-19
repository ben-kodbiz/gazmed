import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Checking RAG Knowledge Base...');
  
  try {
    final file = File('assets/medical_knowledge_rag.json');
    final content = await file.readAsString();
    final data = jsonDecode(content);
    
    print('✅ File loaded: ${content.length} characters');
    
    if (data is Map && data.containsKey('knowledge_base')) {
      final entries = data['knowledge_base'] as List;
      print('📊 Total entries: ${entries.length}');
      
      // Count categories
      final categories = <String, int>{};
      for (final entry in entries) {
        if (entry is Map) {
          final category = entry['category']?.toString() ?? 'unknown';
          categories[category] = (categories[category] ?? 0) + 1;
        }
      }
      
      print('\n📋 Categories:');
      categories.forEach((cat, count) => print('  - $cat: $count'));
      
      // Check coverage
      print('\n🏥 Topic Coverage:');
      final topics = ['bleeding', 'wound', 'fever', 'pain', 'heart', 'breathing'];
      for (final topic in topics) {
        final hasIt = content.toLowerCase().contains(topic);
        print('  ${hasIt ? "✅" : "❌"} $topic');
      }
      
    } else {
      print('⚠️ Unexpected format');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}