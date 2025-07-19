# 🤖 Gaza Medical Assistant - AI Models Reference

## 📋 **Recommended Small LLMs for Medical RAG System**

*All models are <2GB quantized and suitable for PDF/DOCX/TXT extraction pipelines*

| Model | Approx. Quantized Size | GGUF Download Link | Context Window | Notes |
|-------|------------------------|-------------------|----------------|-------|
| **Gemma 3 1B** | ~0.8–2 GB (Q4_Q6 variants) | [Hugging Face – unsloth/gemma-3-1b-it-GGUF](https://huggingface.co/unsloth/gemma-3-1b-it-GGUF) | 128K tokens | Great for long-doc RAG |
| **TinyLlama 1.1B** | ~0.8 GB (Q4_K_M) | [Hugging Face – TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF](https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF) | ~4–8K | Fast and stable on low-end CPU/GPU |
| **Apollo 1.8B** | <2 GB quantized | [Hugging Face – FreedomIntelligence/Apollo-1.8B-GGUF](https://huggingface.co/FreedomIntelligence/Apollo-1.8B-GGUF) | — | **Medical-domain fine-tuned** ⭐ |
| **Apollo 0.5B** | <1 GB quantized | [Hugging Face – FreedomIntelligence/Apollo-0.5B-GGUF](https://huggingface.co/FreedomIntelligence/Apollo-0.5B-GGUF) | — | Smaller medical model |
| **Qwen 0.6B** | ~0.8 GB | [Hugging Face – unsloth/Qwen3-0.6B-GGUF](https://huggingface.co/unsloth/Qwen3-0.6B-GGUF) | — | Multilingual reasoning, solid instruction following |

## ✅ **RAG Suitability Analysis**

### **🏥 Apollo Models (Recommended for Gaza Medical Assistant)**
- **Apollo 1.8B**: Top pick for medical aid-focused tasks
- **Apollo 0.5B**: Lighter alternative for resource-constrained devices
- **Advantage**: Already instruction-tuned on medical content, making Q&A more accurate
- **Use Case**: Primary medical consultation and emergency guidance

### **📚 Gemma 3 1B (Best for Document Processing)**
- **Strength**: 128K token context window—ideal for processing full PDF or DOCX files
- **Use Case**: Long-document retrieval and summarization
- **Perfect for**: Processing hundreds of medical PDFs/manuals

### **⚡ TinyLlama 1.1B (Fastest Performance)**
- **Strength**: Snappy local performance on low-end hardware
- **Use Case**: Speedy chunk-level extractions in RAG pipelines
- **Perfect for**: Real-time medical query processing

### **🌍 Qwen 0.6B (Multilingual Support)**
- **Strength**: Broad language understanding (Arabic + English)
- **Use Case**: Multilingual medical assistance
- **Perfect for**: Gaza's Arabic-speaking population

## 🛠️ **Implementation Setup Tips**

### **Quantization Strategy**
- **Q4_K_M**: Best balance of size and quality (recommended)
- **Q5_K_M**: Higher quality, slightly larger
- **Q6_K**: Maximum quality, largest size
- **Q4_0**: Smallest size, lower quality

### **Gaza Medical Assistant Integration**
```dart
// Current implementation in lib/services/rag_service.dart
Future<String> _getModelPath() async {
  // Priority order for Gaza deployment:
  // 1. Apollo 1.8B (medical-specific)
  // 2. TinyLlama 1.1B (fast performance)
  // 3. Gemma 3 1B (long documents)
  // 4. Qwen 0.6B (multilingual)
}
```

### **PDF/Text Ingestion Pipeline**
- **Tools**: langchain, llama_index, or Haystack
- **Process**: Chunk documents → Generate embeddings → Retrieve relevant context
- **LLM Engine**: llama.cpp, llama-cpp-python, Ollama, or LM Studio

### **Prompt Strategy**
1. Retrieve relevant medical document chunks
2. Append context to user query
3. Generate contextual medical response
4. Include appropriate medical disclaimers

## 💡 **Recommended Implementation Strategy**

### **Phase 1: Core Medical AI (Apollo 1.8B)**
```bash
# Download Apollo 1.8B for medical expertise
wget https://huggingface.co/FreedomIntelligence/Apollo-1.8B-GGUF/resolve/main/apollo-1.8b.q4_k_m.gguf
mv apollo-1.8b.q4_k_m.gguf assets/models/apollo_medical_1.8b.gguf
```

### **Phase 2: Document Processing (Gemma 3 1B)**
```bash
# Download Gemma 3 1B for long document processing
wget https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it.q4_k_m.gguf
mv gemma-3-1b-it.q4_k_m.gguf assets/models/gemma_docs_1b.gguf
```

### **Phase 3: Fallback System (TinyLlama 1.1B)**
```bash
# Download TinyLlama for fast fallback responses
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.q4_k_m.gguf
mv tinyllama-1.1b-chat-v1.0.q4_k_m.gguf assets/models/tinyllama_fallback.gguf
```

## 🎯 **Gaza-Specific Recommendations**

### **Primary Choice: Apollo 1.8B**
- **Why**: Medical-domain fine-tuned, most accurate for medical queries
- **Size**: ~1.5GB quantized (acceptable for Gaza deployment)
- **Performance**: Optimized for medical consultation scenarios

### **Secondary Choice: TinyLlama 1.1B**
- **Why**: Fastest performance on low-spec devices
- **Size**: ~0.8GB (very efficient)
- **Performance**: Real-time responses even on 1GB RAM devices

### **Document Processing: Gemma 3 1B**
- **Why**: 128K context window handles full medical manuals
- **Use**: Background processing of medical PDFs
- **Integration**: Batch processing for knowledge base expansion

## 🔄 **Fallback Validation Strategy**

### **Quality Assurance**
- Always cross-check medical outputs
- Include medical disclaimers
- Provide escalation paths to professional care
- Implement confidence scoring

### **Multi-Model Approach**
1. **Apollo 1.8B**: Primary medical responses
2. **TinyLlama**: Fast fallback for simple queries
3. **Gemma 3 1B**: Document summarization
4. **Enhanced Basic Mode**: Rule-based fallback

## 📱 **APK Size Considerations**

| Configuration | APK Size | Use Case |
|---------------|----------|----------|
| Basic Mode Only | ~74MB | Immediate deployment |
| + TinyLlama | ~154MB | Fast AI responses |
| + Apollo 1.8B | ~224MB | Medical expertise |
| + All Models | ~374MB | Full AI capability |

## 🚀 **Next Steps**

1. **Download Apollo 1.8B** for medical-specific AI
2. **Test integration** with current RAG framework
3. **Validate medical accuracy** with healthcare professionals
4. **Optimize for Gaza deployment** (offline-first, resource-efficient)
5. **Expand medical knowledge base** with hundreds of PDFs

---

**Note**: All models support offline operation after initial download, making them perfect for Gaza's challenging connectivity conditions.