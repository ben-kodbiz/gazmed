import 'dart:io';

void main() async {
  print('🧪 Testing RAG Core Components...');

  // Test 1: Check model file size and accessibility
  print('\n📊 Test 1: Model File Analysis');
  try {
    final modelFile = File('assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf');
    if (await modelFile.exists()) {
      final size = await modelFile.length();
      print('✅ Model file size: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');

      // Check if file is readable
      final bytes = await modelFile.readAsBytes();
      print('✅ Model file is readable: ${bytes.length} bytes');

      // Check file header (GGUF magic number)
      if (bytes.length >= 4) {
        final header = String.fromCharCodes(bytes.take(4));
        print('✅ File header: "$header"');
        if (header == 'GGUF') {
          print('✅ Valid GGUF model file detected');
        } else {
          print('⚠️ Unexpected file header - may not be valid GGUF');
        }
      }
    } else {
      print('❌ Model file not found at: ${modelFile.path}');
    }
  } catch (e) {
    print('❌ Model file test failed: $e');
  }

  // Test 2: Medical Knowledge Base
  print('\n📚 Test 2: Medical Knowledge Base');
  try {
    final knowledgeFile = File('assets/medical_knowledge_rag.json');
    if (await knowledgeFile.exists()) {
      final content = await knowledgeFile.readAsString();
      print('✅ Knowledge base size: ${content.length} characters');

      // Basic JSON validation
      if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
        print('✅ Knowledge base appears to be valid JSON');
      } else {
        print('⚠️ Knowledge base may not be valid JSON');
      }
    } else {
      print('❌ Knowledge base file not found');
    }
  } catch (e) {
    print('❌ Knowledge base test failed: $e');
  }

  // Test 3: System Resources
  print('\n💻 Test 3: System Resources');
  try {
    final info = await Process.run('free', ['-h']);
    if (info.exitCode == 0) {
      print('📊 Memory info:');
      print(info.stdout);
    }
  } catch (e) {
    print('⚠️ Could not get memory info: $e');
  }

  // Test 4: Simulate RAG Query Processing
  print('\n🔄 Test 4: RAG Query Simulation');
  final testQueries = [
    'How to stop bleeding?',
    'كيف أوقف النزيف؟',
    'What to do for fever?',
    'Managing severe pain',
  ];

  for (final query in testQueries) {
    print('Query: "$query"');

    // Simulate Arabic detection
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    print('  Arabic detected: $isArabic');

    // Simulate keyword extraction
    final keywords =
        query
            .toLowerCase()
            .split(RegExp(r'\W+'))
            .where((word) => word.length > 2)
            .take(3)
            .toList();
    print('  Keywords: $keywords');

    print('  ✅ Query processing simulation complete\n');
  }

  print('🏁 RAG Core Tests Completed!');
}
