import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('🔍 Debugging RAG Initialization Issues...');

  try {
    // Step 1: Check if model file exists in assets
    print('\n📁 Step 1: Checking model file in assets...');
    try {
      final assetData = await rootBundle.load(
        'assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf',
      );
      print('✅ Model file found in assets: ${assetData.lengthInBytes} bytes');
    } catch (e) {
      print('❌ Model file not found in assets: $e');
      return;
    }

    // Step 2: Check app documents directory
    print('\n📂 Step 2: Checking app documents directory...');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      print('✅ App directory: ${appDir.path}');

      final modelFile = File('${appDir.path}/Qwen3-0.6B-UD-Q4_K_XL.gguf');
      if (await modelFile.exists()) {
        final size = await modelFile.length();
        print('✅ Model file exists in app directory: $size bytes');
      } else {
        print('⚠️ Model file not yet copied to app directory');
      }
    } catch (e) {
      print('❌ Error accessing app directory: $e');
    }

    // Step 3: Test model copying process
    print('\n📋 Step 3: Testing model copy process...');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/Qwen3-0.6B-UD-Q4_K_XL.gguf');

      if (!await modelFile.exists()) {
        print('📥 Copying model from assets...');
        final assetData = await rootBundle.load(
          'assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf',
        );
        await modelFile.writeAsBytes(assetData.buffer.asUint8List());
        print('✅ Model copied successfully');
      }

      final size = await modelFile.length();
      print('✅ Final model file size: $size bytes');
      print('✅ Model path: ${modelFile.path}');
    } catch (e) {
      print('❌ Error copying model: $e');
    }

    print('\n🎯 Model file diagnostics completed!');
  } catch (e) {
    print('💥 Fatal error: $e');
  }
}
