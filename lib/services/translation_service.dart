import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';

class TranslationService {
  CactusLM? _translator;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing English→Arabic translator...');
      
      // For now, we'll use a simple rule-based translation for medical terms
      // Later we can add a proper GGUF translation model
      _isInitialized = true;
      debugPrint('Translation service ready');
    } catch (e) {
      debugPrint('Translation service initialization failed: $e');
      rethrow;
    }
  }

  Future<String> translateToArabic(String englishText) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // For now, use rule-based translation for common medical terms
      return _ruleBasedTranslation(englishText);
    } catch (e) {
      debugPrint('Translation failed: $e');
      // Return original text if translation fails
      return englishText;
    }
  }

  String _ruleBasedTranslation(String english) {
    // Simple rule-based translation for common medical responses
    String arabic = english;

    // Medical emergency translations
    arabic = arabic.replaceAll('MEDICAL EMERGENCY DETECTED', 'تم اكتشاف حالة طوارئ طبية');
    arabic = arabic.replaceAll('Seek immediate medical attention', 'اطلب العناية الطبية الفورية');
    arabic = arabic.replaceAll('call emergency services', 'اتصل بخدمات الطوارئ');
    arabic = arabic.replaceAll('This is a medical emergency', 'هذه حالة طوارئ طبية');
    arabic = arabic.replaceAll('get professional help NOW', 'احصل على مساعدة مهنية الآن');

    // Fever translations
    arabic = arabic.replaceAll('For fever management:', 'لعلاج الحمى:');
    arabic = arabic.replaceAll('Take paracetamol', 'خذ الباراسيتامول');
    arabic = arabic.replaceAll('Stay well hydrated', 'ابق رطباً جيداً');
    arabic = arabic.replaceAll('Rest and avoid strenuous activity', 'استرح وتجنب النشاط الشاق');
    arabic = arabic.replaceAll('Use cool compresses', 'استخدم الكمادات الباردة');
    arabic = arabic.replaceAll('Monitor temperature regularly', 'راقب درجة الحرارة بانتظام');

    // Wound care translations
    arabic = arabic.replaceAll('For wound care:', 'لعناية الجروح:');
    arabic = arabic.replaceAll('Clean your hands first', 'نظف يديك أولاً');
    arabic = arabic.replaceAll('Apply direct pressure to stop bleeding', 'اضغط مباشرة لوقف النزيف');
    arabic = arabic.replaceAll('Clean wound with clean water', 'نظف الجرح بالماء النظيف');
    arabic = arabic.replaceAll('Apply antiseptic if available', 'ضع المطهر إذا توفر');
    arabic = arabic.replaceAll('Cover with clean bandage', 'غطي بضمادة نظيفة');
    arabic = arabic.replaceAll('Change dressing daily', 'غير الضمادة يومياً');

    // Warning translations
    arabic = arabic.replaceAll('Seek medical help if:', 'اطلب المساعدة الطبية إذا:');
    arabic = arabic.replaceAll('Deep cuts requiring stitches', 'جروح عميقة تحتاج خياطة');
    arabic = arabic.replaceAll('Signs of infection', 'علامات العدوى');
    arabic = arabic.replaceAll('Bleeding won\\'t stop', 'النزيف لا يتوقف');
    arabic = arabic.replaceAll('Fever exceeds 39°C', 'الحمى تتجاوز 39 درجة مئوية');
    arabic = arabic.replaceAll('Persists more than 3 days', 'تستمر أكثر من 3 أيام');

    // General medical advice
    arabic = arabic.replaceAll('Always consult healthcare professionals', 'استشر دائماً أخصائيي الرعاية الصحية');
    arabic = arabic.replaceAll('This information is for educational purposes only', 'هذه المعلومات لأغراض تعليمية فقط');
    arabic = arabic.replaceAll('not a substitute for professional medical care', 'وليست بديلاً عن الرعاية الطبية المهنية');

    // Common phrases
    arabic = arabic.replaceAll('I understand you have a medical concern about:', 'أفهم أن لديك قلق طبي حول:');
    arabic = arabic.replaceAll('While I can provide basic guidance, I recommend:', 'بينما يمكنني تقديم إرشادات أساسية، أنصح بـ:');
    arabic = arabic.replaceAll('Consulting with healthcare professionals when possible', 'استشارة أخصائيي الرعاية الصحية عند الإمكان');
    arabic = arabic.replaceAll('Seeking immediate medical attention for emergencies', 'طلب العناية الطبية الفورية للحالات الطارئة');

    return arabic;
  }

  bool isArabicQuery(String query) {
    // Simple Arabic detection - check for Arabic characters
    final arabicRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    return arabicRegex.hasMatch(query);
  }

  void dispose() {
    _translator?.dispose();
  }
}