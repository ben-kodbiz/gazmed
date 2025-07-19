#!/usr/bin/env python3
"""
Gaza Medical Assistant - Model Download Script
Downloads optimized AI models for offline medical assistance
"""

import os
import sys
import requests
from pathlib import Path
from urllib.parse import urlparse
import hashlib

class ModelDownloader:
    def __init__(self, models_dir="models"):
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(exist_ok=True)
        
        # Model configurations optimized for low-spec devices
        self.available_models = {
            "phi-2-q4": {
                "name": "Phi-2 Q4_K_M (Recommended)",
                "url": "https://huggingface.co/microsoft/phi-2-gguf/resolve/main/phi-2.Q4_K_M.gguf",
                "size": "1.7GB",
                "description": "Microsoft Phi-2 2.7B model, 4-bit quantized for efficiency",
                "ram_requirement": "1-2GB",
                "recommended": True
            },
            "phi-2-q2": {
                "name": "Phi-2 Q2_K (Ultra Low-Spec)",
                "url": "https://huggingface.co/microsoft/phi-2-gguf/resolve/main/phi-2.Q2_K.gguf",
                "size": "1.1GB",
                "description": "Microsoft Phi-2 2.7B model, 2-bit quantized for very low-spec devices",
                "ram_requirement": "512MB-1GB",
                "recommended": False
            },
            "qwen2-1.5b-q4": {
                "name": "Qwen2-1.5B Q4_K_M",
                "url": "https://huggingface.co/Qwen/Qwen2-1.5B-Instruct-GGUF/resolve/main/qwen2-1_5b-instruct-q4_k_m.gguf",
                "size": "1.0GB",
                "description": "Qwen2 1.5B model, good balance of size and performance",
                "ram_requirement": "1GB",
                "recommended": True
            },
            "tinyllama-q4": {
                "name": "TinyLlama Q4_K_M (Smallest)",
                "url": "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
                "size": "700MB",
                "description": "TinyLlama 1.1B model, smallest option for very limited devices",
                "ram_requirement": "512MB",
                "recommended": False
            }
        }
    
    def list_models(self):
        """Display available models"""
        print("Available Models for Gaza Medical Assistant:")
        print("=" * 60)
        
        for key, model in self.available_models.items():
            status = "✅ RECOMMENDED" if model["recommended"] else "⚠️  ALTERNATIVE"
            print(f"\n{status}")
            print(f"ID: {key}")
            print(f"Name: {model['name']}")
            print(f"Size: {model['size']}")
            print(f"RAM Requirement: {model['ram_requirement']}")
            print(f"Description: {model['description']}")
            
            # Check if already downloaded
            filename = self.get_filename_from_url(model['url'])
            if (self.models_dir / filename).exists():
                print("Status: ✅ DOWNLOADED")
            else:
                print("Status: ⬇️  NOT DOWNLOADED")
    
    def get_filename_from_url(self, url):
        """Extract filename from URL"""
        return Path(urlparse(url).path).name
    
    def download_file(self, url, filename, description=""):
        """Download file with progress bar"""
        filepath = self.models_dir / filename
        
        if filepath.exists():
            print(f"✅ {filename} already exists")
            return True
        
        print(f"⬇️  Downloading {description or filename}...")
        print(f"URL: {url}")
        print(f"Destination: {filepath}")
        
        try:
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            print(f"\rProgress: {progress:.1f}% ({downloaded // (1024*1024)}MB / {total_size // (1024*1024)}MB)", end='')
            
            print(f"\n✅ Successfully downloaded {filename}")
            return True
            
        except Exception as e:
            print(f"\n❌ Error downloading {filename}: {e}")
            if filepath.exists():
                filepath.unlink()  # Remove partial file
            return False
    
    def download_model(self, model_id):
        """Download a specific model"""
        if model_id not in self.available_models:
            print(f"❌ Model '{model_id}' not found")
            self.list_models()
            return False
        
        model = self.available_models[model_id]
        filename = self.get_filename_from_url(model['url'])
        
        print(f"Downloading {model['name']}...")
        print(f"Size: {model['size']}")
        print(f"RAM Requirement: {model['ram_requirement']}")
        print(f"Description: {model['description']}")
        print()
        
        success = self.download_file(model['url'], filename, model['name'])
        
        if success:
            print(f"\n🎉 Model ready for Gaza Medical Assistant!")
            print(f"Location: {self.models_dir / filename}")
            print(f"\nNext steps:")
            print(f"1. Update Flutter app to use: {filename}")
            print(f"2. Test on emulator or low-spec device")
            print(f"3. Verify memory usage stays under device limits")
        
        return success
    
    def download_recommended(self):
        """Download all recommended models"""
        print("Downloading recommended models for Gaza Medical Assistant...")
        
        recommended = [key for key, model in self.available_models.items() if model["recommended"]]
        
        for model_id in recommended:
            print(f"\n{'='*60}")
            if not self.download_model(model_id):
                print(f"⚠️  Failed to download {model_id}, continuing with others...")
        
        print(f"\n🎉 Recommended models download completed!")
    
    def verify_model(self, filename):
        """Verify model file integrity"""
        filepath = self.models_dir / filename
        
        if not filepath.exists():
            print(f"❌ Model file not found: {filename}")
            return False
        
        # Basic verification - check file size
        size_mb = filepath.stat().st_size / (1024 * 1024)
        print(f"✅ Model file verified: {filename}")
        print(f"Size: {size_mb:.1f}MB")
        
        # Check if it's a valid GGUF file
        try:
            with open(filepath, 'rb') as f:
                header = f.read(4)
                if header == b'GGUF':
                    print("✅ Valid GGUF format detected")
                    return True
                else:
                    print("⚠️  File format not recognized as GGUF")
                    return False
        except Exception as e:
            print(f"⚠️  Error verifying file: {e}")
            return False
    
    def list_downloaded(self):
        """List all downloaded models"""
        model_files = list(self.models_dir.glob("*.gguf"))
        
        if not model_files:
            print("No models downloaded yet.")
            print("Run with --download to get started.")
            return
        
        print("Downloaded Models:")
        print("=" * 40)
        
        for model_file in model_files:
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"📁 {model_file.name}")
            print(f"   Size: {size_mb:.1f}MB")
            
            # Try to match with known models
            for key, model in self.available_models.items():
                if model_file.name == self.get_filename_from_url(model['url']):
                    print(f"   Type: {model['name']}")
                    print(f"   RAM: {model['ram_requirement']}")
                    break
            print()

def main():
    """Main function"""
    downloader = ModelDownloader()
    
    if len(sys.argv) < 2:
        print("Gaza Medical Assistant - Model Downloader")
        print("=" * 50)
        print("Usage:")
        print("  python download_models.py --list          # List available models")
        print("  python download_models.py --download-all  # Download recommended models")
        print("  python download_models.py --download <id> # Download specific model")
        print("  python download_models.py --downloaded    # List downloaded models")
        print("  python download_models.py --verify <file> # Verify model file")
        print()
        downloader.list_models()
        return
    
    command = sys.argv[1]
    
    if command == "--list":
        downloader.list_models()
    
    elif command == "--download-all":
        downloader.download_recommended()
    
    elif command == "--download" and len(sys.argv) > 2:
        model_id = sys.argv[2]
        downloader.download_model(model_id)
    
    elif command == "--downloaded":
        downloader.list_downloaded()
    
    elif command == "--verify" and len(sys.argv) > 2:
        filename = sys.argv[2]
        downloader.verify_model(filename)
    
    else:
        print("❌ Invalid command or missing arguments")
        print("Use --help for usage information")

if __name__ == "__main__":
    main()