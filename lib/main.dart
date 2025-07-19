import 'package:flutter/material.dart';
import 'medical_chat_screen.dart';
import 'gaza_medical_service.dart';

void main() {
  runApp(const GazaMedicalApp());
}

class GazaMedicalApp extends StatelessWidget {
  const GazaMedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gaza Medical Assistant',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
        fontFamily: 'Roboto',
      ),
      home: const MedicalAppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MedicalAppWrapper extends StatefulWidget {
  const MedicalAppWrapper({super.key});

  @override
  State<MedicalAppWrapper> createState() => _MedicalAppWrapperState();
}

class _MedicalAppWrapperState extends State<MedicalAppWrapper> {
  late final GazaMedicalService _medicalService;

  @override
  void initState() {
    super.initState();
    _medicalService = GazaMedicalService();
    // Initialize asynchronously to avoid blocking the main thread
    _initializeServiceAsync();
  }

  void _initializeServiceAsync() async {
    try {
      await _medicalService.initialize();
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Medical service initialization error: $e');
    }
  }

  @override
  void dispose() {
    _medicalService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MedicalChatScreen(medicalService: _medicalService);
  }
}
