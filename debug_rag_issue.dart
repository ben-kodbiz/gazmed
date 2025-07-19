// Simple debug script to identify RAG issues
void main() {
  print('🔍 Debugging RAG Service Issues...');

  // Simulate the basic medical response logic
  final testQueries = [
    'Managing severe pain naturally',
    'How to bandage wound?',
    'I been shot',
    'كيف أوقف النزيف؟',
    'ما هي أعراض النوبة القلبية؟',
  ];

  for (final query in testQueries) {
    print('\n📝 Query: "$query"');
    final response = getBasicMedicalResponse(query);
    print('📋 Response: ${response.substring(0, 100)}...');
  }
}

String getBasicMedicalResponse(String query) {
  final queryLower = query.toLowerCase();
  print('   Processing: "$queryLower"');

  // Emergency keywords
  if (queryLower.contains('emergency') ||
      queryLower.contains('urgent') ||
      queryLower.contains('severe') ||
      queryLower.contains('shot') ||
      queryLower.contains('bleeding') ||
      queryLower.contains('chest pain') ||
      queryLower.contains('difficulty breathing')) {
    return '''🚨 MEDICAL EMERGENCY DETECTED 🚨

Seek immediate medical attention or call emergency services.

For severe bleeding:
• Apply direct pressure to wound with clean cloth
• Maintain pressure for 15+ minutes
• Elevate injured area above heart level if possible
• Do NOT remove embedded objects
• Get professional help immediately

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

  // Wound care
  if (queryLower.contains('wound') ||
      queryLower.contains('cut') ||
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

Always consult healthcare professionals for proper wound assessment.''';
  }

  // Pain management
  if (queryLower.contains('pain') || queryLower.contains('severe')) {
    return '''For pain management in resource-limited settings:

Natural pain relief:
• Apply cold compress for acute injuries (15-20 minutes)
• Use heat for muscle tension (warm cloth)
• Elevate injured area to reduce swelling
• Rest and avoid aggravating activities

Medication (if available):
• Paracetamol 500-1000mg every 4-6 hours
• Ibuprofen 400mg every 6-8 hours (with food)

⚠️ Seek medical help for:
• Severe, persistent pain
• Signs of infection
• Loss of function

This information is for educational purposes only.''';
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
