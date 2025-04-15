#!/bin/bash

echo "🧠 Starting sanity check for iOS + Flutter + Mapbox..."
echo "────────────────────────────────────────────────────"

# CocoaPods check
if ! command -v pod &> /dev/null; then
  echo "❌ CocoaPods not found. Run: sudo gem install cocoapods"
  exit 1
else
  echo "✅ CocoaPods is installed: $(pod --version)"
fi

# Flutter check
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found. Did you forget to install it?"
  exit 1
else
  echo "✅ Flutter is installed: $(flutter --version | head -n 1)"
fi

# Clean build
echo "🧼 Cleaning Flutter project..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/Flutter/Generated.xcconfig

echo "📦 Getting packages..."
flutter pub get

cd ios || exit

# Check Podfile sanity
echo "📄 Checking Podfile for EXCLUDED_ARCHS..."
if grep -q "EXCLUDED_ARCHS" Podfile; then
  echo "✅ Podfile excludes x86_64 — you're probably on an Apple Silicon Mac"
else
  echo "⚠️ Podfile does NOT exclude x86_64 — if you're on Apple Silicon, expect pain in the simulator"
fi

echo "📡 Installing pods with repo update..."
pod install --repo-update

cd ..

# Check for Mapbox frameworks
echo "🔍 Checking for MapboxMaps.framework..."
if [ -d "ios/Pods/MapboxMaps/MapboxMaps.xcframework" ]; then
  echo "✅ MapboxMaps.framework found!"
else
  echo "❌ MapboxMaps.framework is missing. Check your Podfile or the repo/tag you're using."
fi

echo "🚀 You can now try: flutter run"
echo "📱 If you're on a real device, everything should Just Work™"
echo "🤡 If you're on a simulator and you get EXC_BAD_ACCESS — blame architecture issues"

echo "────────────────────────────────────────────────────"
echo "🧟‍♂️ mapbox_wtf_checker.sh has finished. May Xcode have mercy on your soul."

