import 'dart:io';
import 'lib/services/rag_service.dart';

void main() async {
  print('🔬 Testing RAG Service Directly...');

  final ragService = RAGService();

  try {
    print('📊 Checking system info before initialization...');
    final preInfo = await ragService.getSystemInfo();
    print('Pre-init info: $preInfo');

    print('🚀 Initializing RAG service...');
    await ragService.initialize();

    print('✅ RAG service initialized successfully!');

    print('📊 Checking system info after initialization...');
    final postInfo = await ragService.getSystemInfo();
    print('Post-init info: $postInfo');

    // Test queries
    final testQueries = [
      'How to stop bleeding?',
      'كيف أوقف النزيف؟',
      'What to do for fever?',
      'Managing severe pain naturally',
    ];

    for (final query in testQueries) {
      print('\n🔍 Testing query: "$query"');
      try {
        final response = await ragService.query(query);
        print('✅ Response received:');
        print('   Query: ${response.query}');
        print('   Used embeddings: ${response.usedEmbeddings}');
        print('   Relevant entries: ${response.relevantEntries.length}');
        print('   Has error: ${response.hasError}');
        if (response.hasError) {
          print('   Error: ${response.error}');
        }
        print('   Response: ${response.response.substring(0, 100)}...');
      } catch (e) {
        print('❌ Query failed: $e');
      }
    }
  } catch (e) {
    print('❌ RAG initialization failed: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    ragService.dispose();
  }

  print('\n🏁 RAG test completed');
}
