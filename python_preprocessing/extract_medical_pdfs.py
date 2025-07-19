#!/usr/bin/env python3
"""
Gaza Medical Assistant - PDF Text Extraction Script
Extracts medical knowledge from PDFs and creates a structured knowledge base
"""

import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Any
import re

try:
    import PyPDF2
    import pdfplumber
except ImportError:
    print("Installing required packages...")
    os.system("pip install PyPDF2 pdfplumber")
    import PyPDF2
    import pdfplumber

class MedicalPDFExtractor:
    def __init__(self, output_dir: str = "../assets"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.knowledge_base = []
        
    def extract_text_from_pdf(self, pdf_path: str) -> str:
        """Extract text from PDF using pdfplumber (more reliable)"""
        text = ""
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"
        except Exception as e:
            print(f"Error extracting from {pdf_path}: {e}")
            # Fallback to PyPDF2
            try:
                with open(pdf_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    for page in pdf_reader.pages:
                        text += page.extract_text() + "\n"
            except Exception as e2:
                print(f"Fallback extraction also failed: {e2}")
        
        return text.strip()
    
    def clean_text(self, text: str) -> str:
        """Clean and normalize extracted text"""
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)
        # Remove page numbers and headers/footers
        text = re.sub(r'\n\d+\n', '\n', text)
        # Remove special characters that might cause issues
        text = re.sub(r'[^\w\s\.,;:!?\-\(\)\/]', '', text)
        return text.strip()
    
    def chunk_text(self, text: str, chunk_size: int = 200, overlap: int = 20) -> List[str]:
        """Split text into smaller, more focused chunks for better RAG"""
        # First try to split by sentences or paragraphs
        sentences = re.split(r'[.!?]\s+', text)
        chunks = []
        current_chunk = ""
        
        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue
                
            # If adding this sentence would make chunk too long, save current and start new
            if len(current_chunk) + len(sentence) > chunk_size * 5:  # ~5 chars per word
                if current_chunk.strip():
                    chunks.append(current_chunk.strip())
                current_chunk = sentence
            else:
                current_chunk += (" " + sentence if current_chunk else sentence)
        
        # Add the last chunk
        if current_chunk.strip():
            chunks.append(current_chunk.strip())
        
        # Filter out very short or non-medical chunks
        filtered_chunks = []
        for chunk in chunks:
            if (len(chunk) > 100 and  # Minimum length
                any(word in chunk.lower() for word in [
                    'treatment', 'patient', 'wound', 'surgery', 'medical', 'care',
                    'bleeding', 'pain', 'injury', 'emergency', 'first aid', 'procedure'
                ])):
                filtered_chunks.append(chunk)
        
        return filtered_chunks
    
    def categorize_content(self, text: str) -> str:
        """Categorize medical content based on keywords"""
        text_lower = text.lower()
        
        # War surgery and trauma categories
        if any(word in text_lower for word in ['surgery', 'surgical', 'operation', 'amputation', 'anesthesia']):
            return 'war_surgery'
        elif any(word in text_lower for word in ['bleeding', 'hemorrhage', 'blood loss', 'tourniquet', 'pressure point']):
            return 'bleeding_control'
        elif any(word in text_lower for word in ['wound', 'cut', 'laceration', 'injury', 'trauma', 'bandage', 'dressing']):
            return 'wound_care'
        elif any(word in text_lower for word in ['fracture', 'broken bone', 'splint', 'immobilization']):
            return 'fractures'
        elif any(word in text_lower for word in ['burn', 'thermal', 'chemical burn', 'electrical burn']):
            return 'burns'
        elif any(word in text_lower for word in ['shock', 'hypotension', 'circulation', 'pulse']):
            return 'shock_management'
        elif any(word in text_lower for word in ['airway', 'breathing', 'respiratory', 'ventilation', 'oxygen']):
            return 'respiratory_emergency'
        elif any(word in text_lower for word in ['pain', 'analgesic', 'morphine', 'pain management']):
            return 'pain_management'
        elif any(word in text_lower for word in ['infection', 'antibiotic', 'sepsis', 'contamination']):
            return 'infection_control'
        elif any(word in text_lower for word in ['first aid', 'emergency', 'urgent', 'critical', 'life threatening']):
            return 'emergency_care'
        elif any(word in text_lower for word in ['fever', 'temperature', 'pyrexia']):
            return 'fever_management'
        elif any(word in text_lower for word in ['dehydration', 'fluid', 'electrolyte', 'iv fluid']):
            return 'fluid_management'
        elif any(word in text_lower for word in ['heart', 'cardiac', 'chest pain', 'cpr']):
            return 'cardiovascular'
        elif any(word in text_lower for word in ['triage', 'priority', 'mass casualty']):
            return 'triage'
        else:
            return 'general_medicine'
    
    def extract_medical_guidelines(self, text: str) -> List[Dict[str, Any]]:
        """Extract structured medical guidelines from text"""
        guidelines = []
        
        # Split by common medical section headers
        sections = re.split(r'\n(?=(?:TREATMENT|DIAGNOSIS|SYMPTOMS|MANAGEMENT|PROCEDURE))', text, flags=re.IGNORECASE)
        
        for i, section in enumerate(sections):
            if len(section.strip()) < 100:  # Skip very short sections
                continue
                
            chunks = self.chunk_text(section)
            category = self.categorize_content(section)
            
            for j, chunk in enumerate(chunks):
                guideline = {
                    'id': f"{category}_{i}_{j}",
                    'category': category,
                    'text': chunk,
                    'source': 'medical_pdf',
                    'priority': self.get_priority(chunk),
                    'keywords': self.extract_keywords(chunk)
                }
                guidelines.append(guideline)
        
        return guidelines
    
    def get_priority(self, text: str) -> str:
        """Determine priority level based on content"""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['emergency', 'urgent', 'critical', 'life-threatening', 'immediate']):
            return 'critical'
        elif any(word in text_lower for word in ['severe', 'serious', 'acute']):
            return 'high'
        elif any(word in text_lower for word in ['chronic', 'mild', 'routine']):
            return 'low'
        else:
            return 'medium'
    
    def extract_keywords(self, text: str) -> List[str]:
        """Extract relevant medical keywords"""
        # Common medical terms to look for
        medical_terms = [
            'fever', 'pain', 'bleeding', 'infection', 'inflammation',
            'treatment', 'medication', 'dosage', 'symptoms', 'diagnosis',
            'emergency', 'first aid', 'wound', 'burn', 'fracture',
            'dehydration', 'diarrhea', 'vomiting', 'nausea',
            'breathing', 'cough', 'chest pain', 'heart rate',
            'blood pressure', 'diabetes', 'insulin', 'glucose'
        ]
        
        keywords = []
        text_lower = text.lower()
        
        for term in medical_terms:
            if term in text_lower:
                keywords.append(term)
        
        return keywords[:10]  # Limit to top 10 keywords
    
    def process_pdf_directory(self, pdf_dir: str):
        """Process all PDFs in a directory"""
        pdf_path = Path(pdf_dir)
        
        if not pdf_path.exists():
            print(f"Directory {pdf_dir} does not exist. Creating sample medical knowledge...")
            self.create_sample_knowledge()
            return
        
        pdf_files = list(pdf_path.glob("*.pdf"))
        
        if not pdf_files:
            print(f"No PDF files found in {pdf_dir}. Creating sample medical knowledge...")
            self.create_sample_knowledge()
            return
        
        print(f"Processing {len(pdf_files)} PDF files...")
        
        for pdf_file in pdf_files:
            print(f"Extracting from: {pdf_file.name}")
            text = self.extract_text_from_pdf(str(pdf_file))
            
            if text:
                cleaned_text = self.clean_text(text)
                guidelines = self.extract_medical_guidelines(cleaned_text)
                self.knowledge_base.extend(guidelines)
                print(f"  Extracted {len(guidelines)} guidelines")
            else:
                print(f"  No text extracted from {pdf_file.name}")
    
    def create_sample_knowledge(self):
        """Create sample medical knowledge when no PDFs are available"""
        sample_knowledge = [
            {
                'id': 'fever_001',
                'category': 'fever_management',
                'text': 'Fever management in resource-limited settings: Administer paracetamol 500-1000mg every 4-6 hours (maximum 4g per day). Ensure adequate fluid intake. Use tepid sponging for high fever. Monitor for danger signs including difficulty breathing, severe headache, or altered consciousness.',
                'source': 'who_guidelines',
                'priority': 'medium',
                'keywords': ['fever', 'paracetamol', 'fluid', 'temperature']
            },
            {
                'id': 'wound_001',
                'category': 'wound_care',
                'text': 'Basic wound care procedure: Clean hands thoroughly. Stop bleeding with direct pressure. Clean wound with clean water or saline. Apply antibiotic ointment if available. Cover with sterile dressing. Change dressing daily and monitor for signs of infection.',
                'source': 'first_aid_manual',
                'priority': 'high',
                'keywords': ['wound', 'bleeding', 'infection', 'dressing', 'antibiotic']
            },
            {
                'id': 'dehydration_001',
                'category': 'dehydration',
                'text': 'Oral rehydration therapy: Mix 1 liter clean water with 6 teaspoons sugar and 1/2 teaspoon salt. Give small frequent sips. For severe dehydration, give 75ml/kg over first 4 hours for children, 3 liters over 6 hours for adults.',
                'source': 'who_guidelines',
                'priority': 'high',
                'keywords': ['dehydration', 'oral rehydration', 'salt', 'sugar', 'fluid']
            },
            {
                'id': 'respiratory_001',
                'category': 'respiratory',
                'text': 'Respiratory distress management: Position patient upright. Ensure airway is clear. Give oxygen if available. For asthma, use bronchodilator inhaler. Seek immediate medical attention for severe breathing difficulty, blue lips, or inability to speak.',
                'source': 'emergency_protocols',
                'priority': 'critical',
                'keywords': ['breathing', 'respiratory', 'asthma', 'oxygen', 'emergency']
            },
            {
                'id': 'emergency_001',
                'category': 'emergency',
                'text': 'Emergency assessment: Check consciousness level, breathing, and pulse. Call for help immediately. Begin CPR if no pulse detected. Control severe bleeding with direct pressure. Keep patient warm and monitor vital signs.',
                'source': 'emergency_protocols',
                'priority': 'critical',
                'keywords': ['emergency', 'cpr', 'bleeding', 'consciousness', 'vital signs']
            }
        ]
        
        self.knowledge_base.extend(sample_knowledge)
        print(f"Created {len(sample_knowledge)} sample medical guidelines")
    
    def save_knowledge_base(self):
        """Save the knowledge base to JSON file"""
        output_file = self.output_dir / "medical_knowledge_rag.json"
        
        # Create structured output
        output_data = {
            'metadata': {
                'total_entries': len(self.knowledge_base),
                'categories': list(set(item['category'] for item in self.knowledge_base)),
                'created_at': str(Path(__file__).stat().st_mtime),
                'version': '1.0'
            },
            'knowledge_base': self.knowledge_base
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"\nKnowledge base saved to: {output_file}")
        print(f"Total entries: {len(self.knowledge_base)}")
        
        # Print category summary
        categories = {}
        for item in self.knowledge_base:
            cat = item['category']
            categories[cat] = categories.get(cat, 0) + 1
        
        print("\nCategory breakdown:")
        for cat, count in sorted(categories.items()):
            print(f"  {cat}: {count} entries")

def main():
    """Main function to run PDF extraction"""
    print("Gaza Medical Assistant - PDF Knowledge Extraction")
    print("=" * 50)
    
    # Check for PDF directory argument
    pdf_dir = sys.argv[1] if len(sys.argv) > 1 else "medical_pdfs"
    
    extractor = MedicalPDFExtractor()
    extractor.process_pdf_directory(pdf_dir)
    extractor.save_knowledge_base()
    
    print("\n" + "=" * 50)
    print("Extraction completed! Knowledge base ready for Flutter app.")
    print("Next steps:")
    print("1. Copy medical_knowledge_rag.json to Flutter assets/")
    print("2. Run Flutter app to initialize local database")
    print("3. Test RAG functionality with medical queries")

if __name__ == "__main__":
    main()