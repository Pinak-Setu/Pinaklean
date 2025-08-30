#!/bin/bash

echo '🚀 PINAKLEAN SOTA LAUNCH DIAGNOSTIC'
echo '===================================='

# Step 1: Check current location
echo '📍 Current location:'
pwd
ls -la

# Step 2: Navigate to PinakleanApp if needed
if [ ! -f 'Package.swift' ]; then
    echo '📁 Not in PinakleanApp directory, navigating...'
    cd PinakleanApp 2>/dev/null || { echo '❌ Cannot find PinakleanApp directory'; exit 1; }
    echo '✅ Navigated to PinakleanApp'
fi

# Step 3: Check Package.swift exists
if [ ! -f 'Package.swift' ]; then
    echo '❌ Package.swift not found'
    echo 'Available files:'
    ls -la
    exit 1
else
    echo '✅ Package.swift found'
fi

# Step 4: Check Swift availability
if ! command -v swift >/dev/null 2>&1; then
    echo '❌ Swift not found in PATH'
    echo 'Please ensure Xcode/Command Line Tools are installed'
    exit 1
else
    echo '✅ Swift found:' Apple Swift version 6.1.2 (swiftlang-6.1.2.1.2 clang-1700.0.13.5)
fi

# Step 5: Clean and resolve
echo '🧹 Cleaning previous build...'
swift package clean >/dev/null 2>&1
echo '🔄 Resolving dependencies...'
swift package resolve >/dev/null 2>&1

# Step 6: Build with diagnostics
echo '🏗️ Building Pinaklean SOTA...'
if swift build --configuration release --verbose; then
    echo '✅ Build successful!'
    
    # Step 7: Launch the app
    echo '🚀 Launching Pinaklean SOTA...'
    if ./build/release/pinaklean-cli; then
        echo '✅ App launched successfully!'
    else
        echo '❌ App launch failed'
        echo 'Trying alternative launch method...'
        
        # Try swift run
        if swift run pinaklean-cli; then
            echo '✅ Alternative launch successful!'
        else
            echo '❌ Alternative launch also failed'
            echo 'Checking executable permissions...'
            ls -la .build/release/pinaklean-cli
            echo 'Try: chmod +x .build/release/pinaklean-cli'
        fi
    fi
else
    echo '❌ Build failed'
    echo 'Check the build errors above'
    echo 'Try: swift package clean && swift package resolve && swift build --configuration release'
fi

echo '🎯 Troubleshooting complete!'
echo ''
echo 'If still having issues, try:'
echo '1. Restart terminal and try again'
echo '2. Check Xcode/Command Line Tools installation'
echo '3. Try: xcode-select --install'
echo '4. Ensure you have write permissions in the directory'
