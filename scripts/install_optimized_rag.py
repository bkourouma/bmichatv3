#!/usr/bin/env python3
"""
Installation script for optimized RAG dependencies.

This script installs the required dependencies for the optimized RAG pipeline
with cross-encoder re-ranking and French-optimized embeddings.
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors."""
    print(f"🔧 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed:")
        print(f"Error: {e.stderr}")
        return None

def check_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ Python 3.8 or higher is required")
        sys.exit(1)
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} detected")

def install_dependencies():
    """Install required dependencies."""
    print("📦 Installing optimized RAG dependencies...")
    
    # Core dependencies
    dependencies = [
        "sentence-transformers>=2.2.0",
        "torch>=1.9.0",
        "transformers>=4.20.0",
        "numpy>=1.21.0",
        "scikit-learn>=1.0.0"
    ]
    
    for dep in dependencies:
        run_command(f"pip install {dep}", f"Installing {dep}")

def verify_installation():
    """Verify that all dependencies are installed correctly."""
    print("🔍 Verifying installation...")
    
    try:
        import sentence_transformers
        print(f"✅ sentence-transformers {sentence_transformers.__version__}")
        
        import torch
        print(f"✅ torch {torch.__version__}")
        
        import transformers
        print(f"✅ transformers {transformers.__version__}")
        
        # Test cross-encoder loading
        from sentence_transformers import CrossEncoder
        model_name = "cross-encoder/ms-marco-MiniLM-L-6-v2"
        print(f"🧪 Testing cross-encoder model: {model_name}")
        
        # This will download the model if not present
        model = CrossEncoder(model_name, max_length=512)
        print("✅ Cross-encoder model loaded successfully")
        
        # Test a simple prediction
        test_pairs = [["Comment faire une réclamation ?", "Pour faire une réclamation, remplissez le formulaire."]]
        scores = model.predict(test_pairs)
        print(f"✅ Cross-encoder test prediction: {scores[0]:.3f}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Verification error: {e}")
        return False

def setup_environment():
    """Setup environment variables for optimized RAG."""
    print("⚙️ Setting up environment configuration...")
    
    env_vars = {
        "ENABLE_RERANKING": "true",
        "RERANKING_MODEL": "cross-encoder/ms-marco-MiniLM-L-6-v2",
        "HIGH_CONFIDENCE_THRESHOLD": "0.8",
        "MEDIUM_CONFIDENCE_THRESHOLD": "0.5",
        "LOW_CONFIDENCE_THRESHOLD": "0.3",
        "SEMANTIC_WEIGHT": "0.6",
        "KEYWORD_WEIGHT": "0.4",
        "SIMILARITY_WEIGHT": "0.3",
        "RERANK_WEIGHT": "0.7"
    }
    
    env_file = Path(".env")
    
    if env_file.exists():
        with open(env_file, "r") as f:
            existing_content = f.read()
    else:
        existing_content = ""
    
    new_vars = []
    for key, value in env_vars.items():
        if key not in existing_content:
            new_vars.append(f"{key}={value}")
    
    if new_vars:
        with open(env_file, "a") as f:
            f.write("\n# Optimized RAG Configuration\n")
            for var in new_vars:
                f.write(f"{var}\n")
        print(f"✅ Added {len(new_vars)} environment variables to .env")
    else:
        print("✅ Environment variables already configured")

def main():
    """Main installation process."""
    print("🚀 BMI Chat - Optimized RAG Installation")
    print("=" * 50)
    
    # Check Python version
    check_python_version()
    
    # Install dependencies
    install_dependencies()
    
    # Verify installation
    if not verify_installation():
        print("❌ Installation verification failed")
        sys.exit(1)
    
    # Setup environment
    setup_environment()
    
    print("\n🎉 Optimized RAG installation completed successfully!")
    print("\nNext steps:")
    print("1. Restart your application to load new dependencies")
    print("2. Run the test script: python tests/test_optimized_rag.py")
    print("3. Upload some documents to test the improved retrieval")
    print("\nFeatures enabled:")
    print("- Cross-encoder re-ranking for better relevance")
    print("- French-optimized embeddings")
    print("- Adaptive confidence thresholds")
    print("- Multi-strategy response generation")

if __name__ == "__main__":
    main()
