import 'dart:io';
import 'dart:convert';
import 'lib/services/model_testing_service.dart';

void main() async {
  print('🚀 Starting Automated Model Testing for Gaza Medical AI');
  print('=' * 60);

  final testingService = ModelTestingService();

  try {
    // Initialize the database
    print('📚 Initializing medical database...');
    await testingService.initializeDatabase();

    // Listen to status updates
    testingService.statusStream.listen((status) {
      print('📊 Status: $status');
    });

    // Listen to test results
    final results = <ModelTestResult>[];
    testingService.resultStream.listen((result) {
      results.add(result);
      print('✅ Completed: ${result.model.name} - ${result.query}');
      print('   Response time: ${result.responseTime.inMilliseconds}ms');
      print('   Quality score: ${result.qualityScore.toStringAsFixed(1)}/10');
      print('   Response length: ${result.responseLength} chars');
      print('');
    });

    print('🧪 Running comprehensive tests on all models...');
    print('Models to test:');
    for (final model in TestModel.values) {
      print('  - ${model.name}');
    }
    print('');

    // Run all model tests
    final allResults = await testingService.runAllModelsTest();

    // Generate and display final report
    print('📋 Generating final test report...');
    final report = testingService.generateTestReport();

    print('\n' + '=' * 60);
    print('🏆 FINAL TEST RESULTS');
    print('=' * 60);

    print('\n📊 BEST MODELS:');
    print('⚡ Best Performance: ${report['bestPerformance']}');
    print('🎯 Best Quality: ${report['bestQuality']}');
    print('🔋 Best Battery: ${report['bestBattery']}');

    print('\n📈 DETAILED RESULTS:');
    final summary = report['testSummary'] as Map<String, dynamic>;

    for (final entry in summary.entries) {
      final modelName = entry.key;
      final stats = entry.value as Map<String, dynamic>;

      print('\n🤖 ${modelName.toUpperCase()}:');
      print(
        '   ⏱️  Avg Response Time: ${(stats['avgResponseTime'] / 1000).toStringAsFixed(1)}s',
      );
      print(
        '   🔋 Avg Battery Usage: ${stats['avgBatteryUsage'].toStringAsFixed(2)}%',
      );
      print('   🧠 Avg Memory Usage: ${stats['avgMemoryUsage']} MB');
      print(
        '   ⭐ Avg Quality Score: ${stats['avgQualityScore'].toStringAsFixed(1)}/10',
      );
      print(
        '   📝 Avg Response Length: ${stats['avgResponseLength'].toStringAsFixed(0)} chars',
      );
      print('   ✅ Total Tests: ${stats['totalQueries']}');
    }

    // Save detailed results to file
    final detailedResults = {
      'testReport': report,
      'allResults': results.map((r) => r.toJson()).toList(),
      'testDate': DateTime.now().toIso8601String(),
      'modelsPath': 'assets/models/',
      'testQueries': [
        "How to stop severe bleeding from a wound?",
        "What are the signs of a heart attack?",
        "How to treat high fever in children?",
        "Emergency treatment for difficulty breathing?",
        "How to manage severe dehydration?",
        "First aid for burns and injuries?",
        "Signs of infection and treatment?",
        "How to help someone having a panic attack?",
        "Treatment for severe diarrhea?",
        "Emergency childbirth assistance?",
      ],
    };

    final resultsFile = File(
      'model_test_results_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await resultsFile.writeAsString(jsonEncode(detailedResults));

    print('\n💾 Detailed results saved to: ${resultsFile.path}');
    print('\n🎉 Automated testing completed successfully!');
    print('Total tests run: ${report['totalTests']}');
  } catch (e) {
    print('❌ Error during testing: $e');
    exit(1);
  } finally {
    testingService.dispose();
  }
}
