# Gaza Medical Assistant

An offline medical assistant app built with the Cactus framework, designed specifically for Gaza's challenging conditions. This app provides AI-powered medical guidance using Retrieval-Augmented Generation (RAG) with lightweight models optimized for low-spec smartphones.

## Features

- **Offline Operation**: Runs entirely on-device without internet connectivity
- **Medical RAG System**: Combines AI with curated medical knowledge base
- **Low-Resource Optimization**: Designed for smartphones with 1-2GB RAM
- **Privacy-First**: No data leaves the device
- **Emergency Protocols**: Quick access to critical medical procedures
- **Arabic/English Support**: Culturally appropriate medical guidance

## Technical Specifications

### AI Model
- **Primary**: Qwen2-1.5B-Instruct (4-bit quantized)
- **Size**: ~1GB after quantization
- **Context**: 1024 tokens (optimized for efficiency)
- **Inference**: CPU-only for maximum compatibility

### Medical Knowledge Base
- Curated medical guidelines for common conditions
- Emergency protocols and first aid procedures
- Treatment options for resource-limited settings
- Warning signs and escalation criteria

### System Requirements
- **Minimum**: Android 6.0+ / iOS 12.0+
- **RAM**: 1GB minimum, 2GB recommended
- **Storage**: 2GB free space
- **CPU**: ARM-based processor

## Installation

### Prerequisites
1. Flutter SDK (3.7.2+)
2. Android Studio / Xcode
3. Cactus framework dependencies

### Build Instructions

```bash
# Clone the repository
git clone <repository-url>
cd cactus/example

# Install dependencies
flutter pub get

# Build for Android (optimized for low-spec devices)
flutter build apk --release --target-platform android-arm,android-arm64

# Build for iOS
flutter build ios --release
```

### Model Setup
The app will automatically download the Qwen2-1.5B model on first run. For offline deployment:

1. Pre-download the model:
   ```
   https://huggingface.co/Qwen/Qwen2-1.5B-Instruct-GGUF/resolve/main/qwen2-1_5b-instruct-q4_k_m.gguf
   ```

2. Bundle with the app or deploy via local network

## Usage

### Basic Medical Queries
- "How to treat fever with limited resources?"
- "First aid for wounds and cuts"
- "Signs of dehydration and treatment"

### Emergency Situations
- The app detects emergency keywords and prioritizes critical information
- Provides immediate action steps for life-threatening conditions
- Clear escalation guidance when professional care is needed

### Quick Access Features
- Pre-defined common medical questions
- Emergency protocol shortcuts
- Symptom checker with treatment guidance

## Medical Knowledge Categories

1. **General Medicine**: Fever, pain, infections
2. **Emergency Medicine**: Trauma, respiratory distress, cardiac events
3. **Gastroenterology**: Diarrhea, dehydration, nutrition
4. **Cardiology**: Hypertension, chest pain
5. **Endocrinology**: Diabetes management
6. **Pediatrics**: Child-specific conditions (planned)

## Privacy & Safety

### Privacy Measures
- All processing happens on-device
- No data transmission or cloud connectivity
- Medical conversations remain private
- No user tracking or analytics

### Medical Disclaimers
- Information is for educational purposes only
- Not a replacement for professional medical care
- Always seek qualified healthcare when available
- Emergency situations require immediate professional attention

## Optimization for Low-Spec Devices

### Memory Management
- Reduced context window (1024 tokens)
- Efficient model quantization (4-bit)
- Minimal UI components
- Garbage collection optimization

### Performance Features
- CPU-only inference for compatibility
- Conservative thread usage (2 threads)
- Lazy loading of medical knowledge
- Optimized embedding generation

### Battery Efficiency
- No background processing
- Minimal network usage (offline-first)
- Efficient model inference
- Power-aware threading

## Development

### Architecture
```
├── lib/
│   ├── main.dart                    # App entry point
│   ├── gaza_medical_service.dart    # Core medical AI service
│   ├── medical_rag_service.dart     # RAG implementation
│   ├── medical_chat_screen.dart     # UI for medical chat
│   └── assets/
│       └── medical_knowledge.json   # Medical knowledge base
```

### Adding Medical Knowledge
1. Edit `assets/medical_knowledge.json`
2. Add new conditions with symptoms, treatments, and warnings
3. Rebuild embeddings by restarting the app

### Customization
- Modify medical guidelines for local protocols
- Add language translations
- Adjust model parameters for different hardware
- Customize UI for specific user needs

## Testing

### Device Testing
Test on actual low-spec devices:
- 1GB RAM Android devices
- Older ARM processors (Cortex-A53)
- Limited storage scenarios
- Poor network connectivity areas

### Medical Accuracy
- Validate against established medical guidelines
- Review with healthcare professionals
- Test emergency scenario responses
- Verify cultural appropriateness

## Deployment

### Gaza-Specific Considerations
- Pre-load all models and data
- Minimize app size for limited storage
- Optimize for intermittent power
- Consider offline distribution methods

### Distribution Options
1. **APK Distribution**: Direct APK sharing
2. **Local Network**: Deploy via local servers
3. **USB/SD Card**: Offline installation packages
4. **Mesh Networks**: Peer-to-peer distribution

## Contributing

### Medical Content
- Healthcare professionals welcome to review content
- Submit medical guideline updates
- Report accuracy issues
- Suggest emergency protocols

### Technical Improvements
- Performance optimizations
- UI/UX enhancements
- Additional language support
- Accessibility features

## License

This project is designed for humanitarian use in Gaza. Please respect the intended use case and ensure any modifications maintain the focus on providing medical assistance in resource-limited settings.

## Support

For technical issues or medical content questions, please create an issue in the repository. For urgent medical situations, always seek immediate professional healthcare when available.

---

**⚠️ MEDICAL DISCLAIMER**: This application provides general medical information only and is not intended to replace professional medical advice, diagnosis, or treatment. Always seek the advice of qualified healthcare providers with any questions regarding medical conditions.