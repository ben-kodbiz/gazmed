#!/bin/bash

# Gaza Medical AI - Emulator Testing Script
# Deploys and tests the complete system on Android emulator

echo "🧪 GAZA MEDICAL AI - EMULATOR TESTING"
echo "====================================="
echo "Testing Arabic-first medical assistant with Qwen3-0.6B"
echo ""

# Configuration
EMULATOR_NAME="gaza_medical_test"
APP_NAME="Gaza Medical Assistant"
TEST_TIMEOUT=300  # 5 minutes timeout

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Check prerequisites
print_status "Checking prerequisites..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Please install Flutter SDK."
    exit 1
fi

# Check Android SDK
if ! command -v adb &> /dev/null; then
    print_error "Android SDK not found. Please install Android Studio."
    exit 1
fi

# Check if model file exists
if [ ! -f "assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf" ]; then
    print_error "Qwen3-0.6B model not found in assets/models/"
    print_error "Please ensure the model file is present before testing."
    exit 1
fi

MODEL_SIZE=$(du -h "assets/models/Qwen3-0.6B-UD-Q4_K_XL.gguf" | cut -f1)
print_success "Qwen3-0.6B model found ($MODEL_SIZE)"

# Check medical knowledge base
if [ ! -f "assets/medical_knowledge_rag.json" ]; then
    print_error "Medical knowledge base not found."
    exit 1
fi

KB_SIZE=$(du -h "assets/medical_knowledge_rag.json" | cut -f1)
print_success "Medical knowledge base found ($KB_SIZE)"

print_success "All prerequisites met"
echo ""

# Step 2: Check for running emulator
print_status "Checking for running Android emulator..."

# Get list of running devices
DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)

if [ $DEVICES -eq 0 ]; then
    print_warning "No Android emulator running."
    print_status "Please start an Android emulator manually:"
    print_status "1. Open Android Studio"
    print_status "2. Go to Tools > AVD Manager"
    print_status "3. Start an emulator (API 28+, 4GB RAM recommended)"
    print_status "4. Wait for emulator to fully boot"
    print_status "5. Run this script again"
    echo ""
    print_status "Or create a Gaza-compatible emulator:"
    print_status "avd create -n gaza_test -k \"system-images;android-28;google_apis;x86_64\" -d \"pixel_4\""
    exit 1
else
    print_success "Android emulator detected"
    
    # Show connected devices
    print_status "Connected devices:"
    adb devices | grep -v "List of devices" | grep -v "^$"
fi

echo ""

# Step 3: Prepare Flutter app
print_status "Preparing Gaza Medical AI for deployment..."

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean > /dev/null 2>&1

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "Flutter dependencies resolved"
else
    print_error "Failed to resolve Flutter dependencies"
    exit 1
fi

echo ""

# Step 4: Deploy to emulator
print_status "Deploying Gaza Medical AI to emulator..."
print_status "This may take a few minutes for first deployment..."

# Deploy with Gaza-specific configuration
flutter run --debug \
    --dart-define=ENVIRONMENT=testing \
    --dart-define=TARGET_REGION=gaza \
    --dart-define=MODEL_PRIMARY=qwen3_0_6b \
    --dart-define=LANGUAGE_PRIORITY=arabic \
    --dart-define=ENABLE_TESTING=true &

FLUTTER_PID=$!

# Wait for deployment
print_status "Waiting for app deployment..."
sleep 10

# Check if Flutter process is still running
if ps -p $FLUTTER_PID > /dev/null; then
    print_success "Gaza Medical AI deployment in progress..."
    print_status "Flutter development server running (PID: $FLUTTER_PID)"
else
    print_error "Flutter deployment failed"
    exit 1
fi

echo ""
print_success "🎉 GAZA MEDICAL AI DEPLOYED TO EMULATOR!"
echo ""

# Step 5: Testing instructions
print_status "📋 MANUAL TESTING INSTRUCTIONS"
echo "================================"
echo ""

print_status "🇵🇸 ARABIC LANGUAGE TESTS:"
echo "Test these Arabic queries in the app:"
echo ""
echo "1. Emergency Bleeding (Palestinian dialect):"
echo "   شو الازم اعمل للجرح اللي بينزف كتير؟"
echo ""
echo "2. Heart Attack Symptoms (MSA):"
echo "   ما هي أعراض النوبة القلبية؟"
echo ""
echo "3. Child Fever (Gaza context):"
echo "   طفلي عنده حمى عالية ماذا أفعل؟"
echo ""
echo "4. Breathing Emergency:"
echo "   صعوبة شديدة في التنفس - حالة طارئة"
echo ""
echo "5. Dehydration Treatment:"
echo "   علامات الجفاف وكيف أعالجه بالموارد المتاحة؟"
echo ""

print_status "🏥 MEDICAL SCENARIO VALIDATION:"
echo "Verify the app provides:"
echo "✅ Accurate medical responses in Arabic"
echo "✅ Emergency protocol activation"
echo "✅ Gaza-specific resource adaptations"
echo "✅ Appropriate medical disclaimers"
echo "✅ Professional referral recommendations"
echo ""

print_status "⚡ PERFORMANCE MONITORING:"
echo "Check these metrics:"
echo "✅ Model loading time (<15 seconds)"
echo "✅ Query response time (<1 second)"
echo "✅ Arabic text rendering (RTL support)"
echo "✅ UI responsiveness and smoothness"
echo "✅ Memory usage (should be reasonable)"
echo ""

print_status "🧪 TESTING CHECKLIST:"
echo "□ App launches successfully"
echo "□ Qwen3-0.6B model loads without errors"
echo "□ Arabic welcome message displays correctly"
echo "□ Arabic queries are processed accurately"
echo "□ Medical responses are appropriate and helpful"
echo "□ Emergency scenarios are handled properly"
echo "□ RTL text rendering works correctly"
echo "□ App remains stable during testing"
echo "□ Offline operation confirmed (no internet needed)"
echo "□ Battery usage appears reasonable"
echo ""

print_status "🎯 SUCCESS CRITERIA:"
echo "✅ All Arabic queries processed correctly"
echo "✅ Medical responses accurate and helpful"
echo "✅ No crashes or critical errors"
echo "✅ Response time <1 second"
echo "✅ Proper Arabic text display"
echo "✅ Gaza medical scenarios handled appropriately"
echo ""

print_warning "📱 EMULATOR TESTING NOTES:"
echo "• Model performance may be slower on emulator than real device"
echo "• Arabic text rendering should work correctly"
echo "• Test both portrait and landscape orientations"
echo "• Try various query lengths and complexities"
echo "• Monitor for any memory leaks during extended use"
echo ""

print_status "🔧 TROUBLESHOOTING:"
echo "If you encounter issues:"
echo "• Check emulator has sufficient RAM (4GB+ recommended)"
echo "• Ensure model file is properly bundled in assets"
echo "• Verify Arabic fonts are rendering correctly"
echo "• Check Flutter console for any error messages"
echo "• Try restarting the app if model loading fails"
echo ""

print_success "🚀 GAZA MEDICAL AI READY FOR TESTING!"
print_status "The app is now running on the emulator."
print_status "Follow the testing instructions above to validate functionality."
print_status "Press Ctrl+C to stop the Flutter development server when done."
echo ""

# Keep the script running to maintain Flutter connection
print_status "Monitoring Flutter development server..."
print_status "Press Ctrl+C to stop testing and exit."

# Wait for user to stop
wait $FLUTTER_PID

print_status "Gaza Medical AI emulator testing completed."
print_success "Thank you for testing the Arabic-first medical assistant!"