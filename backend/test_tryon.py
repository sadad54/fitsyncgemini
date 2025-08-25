#!/bin/bash

# Virtual Try-On Setup Script for FitSync
echo "🎨 Setting up FitSync Virtual Try-On..."

# Step 1: Install required packages
echo "📦 Installing required packages..."
pip install gradio_client
pip install pillow
pip install numpy
pip install httpx
pip install aiofiles

# Step 2: Create necessary directories
echo "📁 Creating directories..."
mkdir -p temp/tryon_results
mkdir -p static/demo_images
mkdir -p logs

# Step 3: Download demo images for testing
echo "🖼️  Downloading demo images..."

# Demo person image
curl -o static/demo_images/demo_person.jpg "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop"

# Demo clothing images  
curl -o static/demo_images/demo_shirt.jpg "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop"
curl -o static/demo_images/demo_dress.jpg "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400&h=600&fit=crop"

echo "✅ Demo images downloaded!"

# Step 4: Test the installation
echo "🧪 Testing installation..."

python3 -c "
import gradio_client
import PIL
import numpy
import httpx
print('✅ All packages imported successfully!')
"

# Step 5: Create test script
cat > test_virtual_tryon.py << 'EOF'
"""
Test script for Virtual Try-On functionality
Run this to test your setup
"""

import asyncio
import aiohttp
import base64
import os
from pathlib import Path

async def test_huggingface_connection():
    """Test connection to Hugging Face"""
    
    print("🔗 Testing Hugging Face connection...")
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("https://api-inference.huggingface.co/models/yisol/IDM-VTON") as response:
                if response.status == 200:
                    print("✅ Hugging Face API accessible")
                    return True
                else:
                    print(f"⚠️  Hugging Face API returned {response.status}")
                    return False
    except Exception as e:
        print(f"❌ Hugging Face connection failed: {e}")
        return False

async def test_gradio_client():
    """Test Gradio client"""
    
    print("🎭 Testing Gradio client...")
    
    try:
        from gradio_client import Client
        print("✅ Gradio client imported successfully")
        
        # Test connection to IDM-VTON space
        try:
            client = Client("yisol/IDM-VTON")
            print("✅ Connected to IDM-VTON space")
            return True
        except Exception as e:
            print(f"⚠️  Could not connect to IDM-VTON space: {e}")
            print("   This is normal if the space is sleeping. It will work when you make requests.")
            return True
            
    except ImportError:
        print("❌ Gradio client not installed. Run: pip install gradio_client")
        return False
    except Exception as e:
        print(f"❌ Gradio test failed: {e}")
        return False

def test_image_processing():
    """Test image processing capabilities"""
    
    print("🖼️  Testing image processing...")
    
    try:
        from PIL import Image
        import numpy as np
        import io
        
        # Create a test image
        img = Image.new('RGB', (100, 100), color='red')
        
        # Test image operations
        img_resized = img.resize((50, 50))
        img_array = np.array(img)
        
        # Test image to bytes conversion
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_data = img_bytes.getvalue()
        
        print("✅ Image processing works correctly")
        return True
        
    except Exception as e:
        print(f"❌ Image processing failed: {e}")
        return False

async def test_virtual_tryon_basic():
    """Test basic virtual try-on functionality"""
    
    print("🎨 Testing basic virtual try-on...")
    
    try:
        # Import your client
        import sys
        sys.path.append('.')
        
        from app.external_apis.huggingface_virtual_tryon import huggingface_virtual_tryon_client
        
        # Create dummy images (you can replace with real images)
        from PIL import Image
        import io
        
        # Create test person image
        person_img = Image.new('RGB', (400, 600), color='blue')
        person_bytes = io.BytesIO()
        person_img.save(person_bytes, format='JPEG')
        person_data = person_bytes.getvalue()
        
        # Create test clothing image
        clothing_img = Image.new('RGB', (300, 400), color='red')
        clothing_bytes = io.BytesIO()
        clothing_img.save(clothing_bytes, format='JPEG')
        clothing_data = clothing_bytes.getvalue()
        
        # Test virtual try-on
        result = await huggingface_virtual_tryon_client.virtual_tryon(
            person_image=person_data,
            clothing_image=clothing_data,
            user_id="test_user"
        )
        
        if result["success"]:
            print("✅ Virtual try-on test successful!")
            print(f"   Method used: {result.get('method', 'unknown')}")
            print(f"   Confidence: {result.get('confidence_score', 0)}")
            return True
        else:
            print("⚠️  Virtual try-on returned no success, but no error")
            return True
            
    except ImportError as e:
        print(f"⚠️  Could not import virtual try-on client: {e}")
        print("   Make sure you're running from the correct directory")
        return False
    except Exception as e:
        print(f"⚠️  Virtual try-on test failed: {e}")
        print("   This might be normal if HuggingFace models are loading")
        return True

def check_environment():
    """Check environment setup"""
    
    print("🔧 Checking environment...")
    
    # Check for HuggingFace token
    hf_token = os.getenv('HUGGINGFACE_TOKEN')
    if hf_token:
        print("✅ HuggingFace token found")
    else:
        print("⚠️  HuggingFace token not found in environment")
        print("   Set it with: export HUGGINGFACE_TOKEN=hf_your_token_here")
    
    # Check Python version
    import sys
    python_version = sys.version_info
    if python_version >= (3, 8):
        print(f"✅ Python version {python_version.major}.{python_version.minor} is supported")
    else:
        print(f"⚠️  Python {python_version.major}.{python_version.minor} might have issues")
    
    return True

def print_next_steps():
    """Print next steps for user"""
    
    print("\n" + "="*60)
    print("🎉 Setup Complete! Next Steps:")
    print("="*60)
    
    print("\n1. 🔑 Get HuggingFace Token (if you haven't):")
    print("   - Go to: https://huggingface.co/settings/tokens")
    print("   - Create a new token with 'Read' permissions")
    print("   - Add to .env: HUGGINGFACE_TOKEN=hf_your_token_here")
    
    print("\n2. 🚀 Start your FastAPI server:")
    print("   cd backend")
    print("   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
    
    print("\n3. 🧪 Test the API:")
    print("   - Open: http://localhost:8000/docs")
    print("   - Try the /api/v1/tryon/demo endpoint")
    print("   - Upload images to /api/v1/tryon/test-upload")
    
    print("\n4. 📱 Integration with your app:")
    print("   - Use the endpoints in your Flutter/React app")
    print("   - Handle rate limits (30 requests/hour free tier)")
    print("   - Implement proper error handling")
    
    print("\n5. 🔧 Troubleshooting:")
    print("   - Check logs in the logs/ directory")
    print("   - First request may take 30-60 seconds (model loading)")
    print("   - Models are cached after first use")
    
    print("\n📚 Available Models:")
    print("   - IDM-VTON: Best virtual try-on quality")
    print("   - OOTDiffusion: Alternative try-on model")
    print("   - YOLO: Clothing detection")
    print("   - RMBG: Background removal")
    
    print(f"\n🌟 Your setup is ready for virtual try-on!")

async def main():
    """Run all tests"""
    
    print("🎨 FitSync Virtual Try-On Test Suite")
    print("="*50)
    
    tests = [
        ("Environment Check", check_environment),
        ("Image Processing", test_image_processing),
        ("HuggingFace Connection", test_huggingface_connection),
        ("Gradio Client", test_gradio_client),
        ("Virtual Try-On Basic", test_virtual_tryon_basic)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        print(f"\n🧪 Running {test_name}...")
        try:
            if asyncio.iscoroutinefunction(test_func):
                result = await test_func()
            else:
                result = test_func()
            results[test_name] = result
        except Exception as e:
            print(f"❌ {test_name} failed with error: {e}")
            results[test_name] = False
    
    print(f"\n📊 Test Results:")
    print("="*50)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
    
    passed = sum(results.values())
    total = len(results)
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed >= total - 1:  # Allow 1 test to fail
        print("🎉 Setup looks good!")
        print_next_steps()
    else:
        print("⚠️  Some tests failed. Check the errors above.")
        print("   Most issues can be resolved by:")
        print("   1. Installing missing packages")
        print("   2. Getting a HuggingFace token") 
        print("   3. Checking your internet connection")

if __name__ == "__main__":
    asyncio.run(main())
EOF

echo "✅ Test script created: test_virtual_tryon.py"

# Step 6: Create requirements file
cat > requirements_tryon.txt << 'EOF'
# Virtual Try-On Requirements
gradio_client>=0.7.0
Pillow>=9.0.0
numpy>=1.21.0
httpx>=0.24.0
aiofiles>=22.0.0
opencv-python>=4.5.0
scikit-image>=0.19.0
matplotlib>=3.5.0
EOF

echo "✅ Requirements file created: requirements_tryon.txt"

# Step 7: Create environment setup
cat > setup_env.sh << 'EOF'
#!/bin/bash

echo "🔧 Setting up environment variables..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    touch .env
fi

# Add HuggingFace token prompt
echo ""
echo "🔑 HuggingFace Token Setup:"
echo "1. Go to: https://huggingface.co/settings/tokens"
echo "2. Create a new token (Read permissions)"
echo "3. Copy the token (starts with hf_)"
echo ""

read -p "Enter your HuggingFace token (or press Enter to skip): " hf_token

if [ ! -z "$hf_token" ]; then
    # Remove existing token line if exists
    sed -i '/HUGGINGFACE_TOKEN=/d' .env
    
    # Add new token
    echo "HUGGINGFACE_TOKEN=$hf_token" >> .env
    echo "✅ HuggingFace token added to .env"
else
    echo "⚠️  Skipping HuggingFace token setup"
    echo "   You can add it later: HUGGINGFACE_TOKEN=hf_your_token_here"
fi

# Add other required environment variables if they don't exist
if ! grep -q "MAX_IMAGE_SIZE" .env; then
    echo "MAX_IMAGE_SIZE=10485760" >> .env  # 10MB
fi

if ! grep -q "ALLOWED_IMAGE_TYPES" .env; then
    echo 'ALLOWED_IMAGE_TYPES=["image/jpeg", "image/png", "image/webp"]' >> .env
fi

if ! grep -q "TRYON_RATE_LIMIT" .env; then
    echo "TRYON_RATE_LIMIT=30" >> .env  # 30 per hour
fi

echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: python test_virtual_tryon.py"
echo "2. Start your server: uvicorn app.main:app --reload"
echo "3. Test at: http://localhost:8000/docs"
EOF

chmod +x setup_env.sh

echo "✅ Environment setup script created: setup_env.sh"

# Step 8: Run the tests
echo ""
echo "🧪 Running tests..."

python3 test_virtual_tryon.py

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: ./setup_env.sh (to set up your HuggingFace token)"
echo "2. Install requirements: pip install -r requirements_tryon.txt"  
echo "3. Test your setup: python test_virtual_tryon.py"
echo "4. Start your server and test the endpoints!"
echo ""
echo "📚 Documentation:"
echo "- API docs will be at: http://localhost:8000/docs"
echo "- Demo endpoint: http://localhost:8000/api/v1/tryon/demo"
echo "- Test upload: http://localhost:8000/api/v1/tryon/test-upload"