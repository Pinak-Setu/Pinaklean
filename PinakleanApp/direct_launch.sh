#!/bin/bash

echo "🧹 Pinaklean Liquid Crystal UI - Direct Launch"
echo "This will launch the app with the new UI design"
echo ""

# Kill any existing processes
killall Pinaklean 2>/dev/null || true
sleep 1

# Launch the app directly
if [ -f "build/release/Pinaklean.app/Contents/MacOS/Pinaklean" ]; then
    echo "✅ Launching Pinaklean..."
    echo "🔍 Look for: Custom app icon in Dock"
    echo "🏹 Look for: Bow and arrow in menu bar"
    echo "✨ Look for: Liquid Crystal UI in the app window"
    echo ""
    open build/release/Pinaklean.app
else
    echo "❌ App not found. Please build first:"
    echo "swift build --configuration release --product Pinaklean"
fi
