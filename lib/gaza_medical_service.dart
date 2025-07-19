import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'services/rag_service.dart';
import 'services/document_processor.dart';
import 'database/medical_database.dart';

class GazaMedicalService {
  RAGService? _ragService;

  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String> status = ValueNotifier(
    'Initializing Gaza Medical Assistant with RAG...',
  );
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<void> processUploadedDocument(File file) async {
    if (_ragService == null) {
      debugPrint('RAGService not initialized. Cannot process document.');
      return;
    }

    isLoading.value = true;
    status.value = 'Processing uploaded document: ${file.path.split('/').last}...';

    try {
      final documentProcessor = DocumentProcessor();
      final extractedText = await documentProcessor.extractText(file);
      final chunks = await documentProcessor.chunkText(extractedText, fileName: file.path.split('/').last);

      for (final chunk in chunks) {
        final embedding = await _ragService!.embedding(chunk.text);
        await _ragService!.addKnowledgeEntry(
          MedicalKnowledgeEntry(
            entryId: chunk.id,
            category: chunk.category,
            text: chunk.text,
            source: chunk.source,
            priority: chunk.priority,
            keywords: chunk.keywords,
            embedding: embedding,
          ),
        );
      }
      status.value = 'Document "${file.path.split('/').last}" processed and added to knowledge base.';
    } catch (e) {
      debugPrint('Error processing document: $e');
      error.value = 'Failed to process document: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initialize() async {
    try {
      status.value = 'Initializing Gaza Medical Assistant...';
      _ragService = RAGService();

      _ragService!.statusStream.listen((statusText) {
        status.value = statusText;
      });

      _ragService!.progressStream.listen((progress) {
        // Update progress if needed
      });

      await _ragService!.initialize();

      status.value = 'Gaza Medical Assistant ready!';
      isLoading.value = false;
      _addWelcomeMessage();
    } catch (e) {
      debugPrint('RAG system initialization failed: $e');
      _ragService = null;
      status.value = 'Gaza Medical Assistant (Basic Mode)';
      isLoading.value = false;
      _addFallbackWelcomeMessage();
    }
  }

  void _addFallbackWelcomeMessage() {
    final welcomeMsg = ChatMessage(
      role: 'assistant',
      content: '''🏥 Gaza Medical Assistant (Basic Mode)

The AI system is currently unavailable, but I can still provide basic medical guidance.

I can help with:
• Basic symptom information
• First aid procedures
• When to seek medical help
• General health advice

⚠️ IMPORTANT: This is for informational purposes only. Seek professional medical care when possible.

Please describe your medical concern, and I'll provide basic guidance.''',
    );

    messages.value = [welcomeMsg];
  }

  void _addWelcomeMessage() {
    final welcomeMsg = ChatMessage(
      role: 'assistant',
      content: '''🏥 مساعد غزة الطبي - Gaza Medical Assistant

أهلاً وسهلاً! أنا هنا لتقديم الإرشادات الطبية عندما تكون الرعاية الصحية محدودة.

يمكنني المساعدة في:
• تقييم الأعراض والعلاج الأساسي
• إجراءات الإسعافات الأولية الطارئة
• إرشادات الأدوية بالموارد المتاحة
• مراقبة الصحة والوقاية

Welcome! I can provide medical guidance when healthcare access is limited:
• Symptom assessment and basic treatment
• Emergency first aid procedures
• Health monitoring and prevention

⚠️ مهم: هذه المعلومات لأغراض تعليمية فقط. اطلب الرعاية الطبية المهنية عند الإمكان.
⚠️ IMPORTANT: This is for informational purposes only. Seek professional medical care when possible.

كيف يمكنني مساعدتك اليوم؟ How can I help you today?''',
    );

    messages.value = [welcomeMsg];
  }

  Future<void> sendMedicalQuery(String query) async {
    isLoading.value = true;

    final userMsg = ChatMessage(role: 'user', content: query);
    messages.value = [
      ...messages.value,
      userMsg,
      ChatMessage(role: 'assistant', content: ''),
    ];

    try {
      if (_ragService != null) {
        final ragResponse = await _ragService!
            .query(query)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('RAG timeout - using basic medical response');
                return RAGResponse(
                  query: query,
                  response: '',
                  relevantEntries: [],
                  usedEmbeddings: false,
                  error: 'AI response timeout - using basic mode',
                );
              },
            );

        if (ragResponse.hasError) {
          debugPrint('RAG Error: ${ragResponse.error}');
          final basicResponse = _getBasicMedicalResponse(query);
          debugPrint(
            'Using basic response: ${basicResponse.substring(0, 50)}...',
          );
          _updateLastMessage(basicResponse);
        } else {
          _updateLastMessage(ragResponse.response);
        }
      } else {
        _updateLastMessage(_getBasicMedicalResponse(query));
      }
    } catch (e) {
      debugPrint('Medical query error: $e');
      _updateLastMessage(_getBasicMedicalResponse(query));
    }

    isLoading.value = false;
  }

  String _getBasicMedicalResponse(String query) {
    final queryLower = query.toLowerCase();
    debugPrint('RAG system unavy: "$queryLower"');

    // Emergency keywords
    if (queryLower.contains('emergency') ||
        queryLower.contains('urgent') ||
        queryLower.contains('severe') ||
        queryLower.contains('shot') ||
        queryLower.contains('bleeding') ||
        queryLower.contains('chest pain') ||
        queryLower.contains('difficulty breathing') ||
        queryLower.contains('breathing difficulties') ||
        queryLower.contains('breathing problems')) {
      return '''🚨 MEDICAL EMERGENCY DETECTED 🚨

Seek immediate medical attention or call emergency services.

For severe bleeding:
• Apply direct pressure to wound with clean cloth
• Maintain pressure for 15+ minutes
• Elevate injured area above heart level if possible
• Do NOT remove embedded objects
• Get professional help immediately

For chest pain or breathing difficulties:
• Call for help immediately
• Stay calm and sit upright
• Loosen tight clothing
• If available, chew aspirin (unless allergic)

⚠️ This is a medical emergency - get professional help NOW.''';
    }

    // Arabic queries
    if (query.contains('نزيف') || query.contains('دم')) {
      return '''لإيقاف النزيف الشديد:

• اضغط مباشرة على الجرح بقطعة قماش نظيفة
• حافظ على الضغط لمدة 15 دقيقة على الأقل
• ارفع المنطقة المصابة فوق مستوى القلب إذا أمكن
• لا تزيل الأجسام المغروسة في الجرح
• اطلب المساعدة الطبية فوراً

⚠️ هذه حالة طوارئ طبية - احصل على مساعدة مهنية الآن.''';
    }

    if (query.contains('قلبية') || query.contains('قلب')) {
      return '''أعراض النوبة القلبية:

• ألم شديد أو ضغط في الصدر
• ألم ينتشر إلى الذراع اليسرى أو الفك أو الظهر
• ضيق في التنفس
• تعرق بارد
• غثيان أو دوار

⚠️ إذا ظهرت هذه الأعراض، اطلب المساعدة الطبية فوراً.''';
    }

    if (query.contains('حمى') || query.contains('حرارة')) {
      return '''لعلاج الحمى العالية:

• استخدم الباراسيتامول بالجرعة المناسبة
• قدم الكثير من السوائل لمنع الجفاف
• استخدم كمادات باردة
• لا تستخدم الكحول للتبريد
• اطلب المساعدة الطبية إذا تجاوزت الحمى 39.5 درجة مئوية

⚠️ راقب الأعراض واطلب المساعدة الطبية عند الحاجة.''';
    }

    // Fever
    if (queryLower.contains('fever') || queryLower.contains('temperature')) {
      return '''For fever management:

• Take paracetamol 500-1000mg every 4-6 hours
• Stay well hydrated with water or oral rehydration solution
• Rest and avoid strenuous activity
• Use cool compresses on forehead
• Monitor temperature regularly

⚠️ Seek medical help if:
• Fever exceeds 39°C (102°F)
• Persists more than 3 days
• Accompanied by severe symptoms

Always consult healthcare professionals when available.''';
    }

    // Wound care
    if (queryLower.contains('wound') ||
        queryLower.contains('cut') ||
        queryLower.contains('bleeding') ||
        queryLower.contains('bandage') ||
        queryLower.contains('injury')) {
      return '''For wound care:

1. Clean your hands first
2. Apply direct pressure to stop bleeding
3. Clean wound with clean water
4. Apply antiseptic if available
5. Cover with clean bandage
6. Change dressing daily

⚠️ Seek medical help if:
• Deep cuts requiring stitches
• Signs of infection (redness, swelling, pus)
• Bleeding won't stop
• Caused by dirty/rusty objects

Always consult healthcare professionals for proper wound assessment.''';
    }

    // Pain management
    if (queryLower.contains('pain') && queryLower.contains('severe')) {
      return '''For severe pain management in resource-limited settings:

Natural pain relief:
• Apply cold compress for acute injuries (15-20 minutes)
• Use heat for muscle tension (warm cloth)
• Elevate injured area to reduce swelling
• Rest and avoid aggravating activities
• Deep breathing and relaxation techniques

Medication (if available):
• Paracetamol 500-1000mg every 4-6 hours
• Ibuprofen 400mg every 6-8 hours (with food)
• Do not exceed recommended doses

⚠️ Seek medical help for:
• Severe, persistent pain
• Signs of infection
• Loss of function
• Pain with fever

This information is for educational purposes only.''';
    }

    // Fractures and broken bones
    if (queryLower.contains('broken') ||
        queryLower.contains('fracture') ||
        queryLower.contains('bone') ||
        queryLower.contains('leg') ||
        queryLower.contains('arm') ||
        queryLower.contains('ankle') ||
        queryLower.contains('wrist')) {
      return '''For suspected fractures:

🚨 IMPORTANT: Do not move the injured person unless absolutely necessary.

Immediate care:
• Keep the injured area still and supported
• Apply ice wrapped in cloth (not directly on skin)
• Elevate if possible without causing pain
• Do not try to realign the bone
• Seek immediate medical attention

⚠️ Signs of serious fracture:
• Bone visible through skin
• Severe deformity
• Loss of circulation (blue/cold fingers/toes)
• Numbness or inability to move

This requires immediate emergency medical care.''';
    }

    // Default response
    return '''I understand you have a medical concern about: "$query"

While I can provide basic guidance, I recommend:

• Consulting with healthcare professionals when possible
• Seeking immediate medical attention for emergencies
• Following established medical protocols
• Monitoring symptoms carefully

For specific medical advice, please consult qualified healthcare providers who can properly assess your condition.

⚠️ This information is for educational purposes only and not a substitute for professional medical care.''';
  }

  void _updateLastMessage(String content) {
    final msgs = List<ChatMessage>.from(messages.value);
    if (msgs.isNotEmpty && msgs.last.role == 'assistant') {
      msgs[msgs.length - 1] = ChatMessage(role: 'assistant', content: content);
      messages.value = msgs;
    }
  }

  void clearConversation() {
    messages.value = [];
    _addWelcomeMessage();
  }

  List<String> getQuickMedicalQueries() {
    return [
      'How to stop bleeding from wounds?',
      'What to do for high fever?',
      'Emergency breathing difficulties',
      'Managing severe pain naturally',
      'Treating diarrhea and vomiting',
      'Recognizing heart attack symptoms',
    ];
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    if (_ragService == null) {
      return {
        'initialized': false,
        'embeddings_generated': false,
        'total_entries': 0,
        'entries_with_embeddings': 0,
        'categories': {},
        'model_loaded': false,
      };
    }
    return await _ragService!.getSystemInfo();
  }

  void dispose() {
    _ragService?.dispose();
    messages.dispose();
    isLoading.dispose();
    status.dispose();
    error.dispose();
  }
}
