#!/bin/bash

# Pinaklean macOS App Launcher
# This script opens the Pinaklean app with the Liquid Crystal UI

echo "🧹 Launching Pinaklean - Liquid Crystal macOS Cleanup Toolkit"

# Check if the app exists
if [ -f "build/release/Pinaklean.app/Contents/MacOS/Pinaklean" ]; then
    echo "✅ App found - launching..."
    open build/release/Pinaklean.app
    echo "🎉 Pinaklean launched! Look for:"
    echo "   - App icon in Dock (with your custom image)"
    echo "   - Bow and arrow (🏹) in menu bar"
    echo "   - Beautiful Liquid Crystal interface"
else
    echo "❌ App not found. Please build first:"
    echo "   swift build --configuration release --product Pinaklean"
fi
