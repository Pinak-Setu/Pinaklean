#!/bin/bash

# Simple Pinaklean Release Script
# Creates a basic macOS app bundle and DMG for distribution

set -e

echo "🚀 Creating Simple Pinaklean Release"
echo "==================================="

# Configuration
VERSION="1.0.0"
APP_NAME="Pinaklean"
BUILD_DIR="./build"
RELEASE_DIR="$BUILD_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$RELEASE_DIR"

# Build the CLI tool (this works)
echo "🔨 Building CLI tool..."
cd PinakleanApp
swift build --product pinaklean-cli --configuration release

# Create a simple wrapper script for the GUI
echo "📝 Creating GUI wrapper..."
cat > "$APP_NAME.sh" << 'EOF'
#!/bin/bash

# Pinaklean GUI Launcher
# This is a temporary wrapper until full GUI is ready

echo "🧹 Pinaklean v1.0.0"
echo "=================="
echo ""
echo "Welcome to Pinaklean - Safe macOS cleanup toolkit!"
echo ""
echo "📋 Available Commands:"
echo "  scan    - Scan for cleanable files"
echo "  clean   - Clean detected files"
echo "  auto    - Automatic cleanup"
echo "  --help  - Show help"
echo ""
echo "🚀 Launching CLI interface..."
echo ""

# Launch the CLI tool
exec "$(dirname "$0")/Resources/pinaklean-cli" "$@"
EOF

chmod +x "$APP_NAME.sh"

# Copy CLI executable
echo "📋 Copying executable..."
cp "./.build/x86_64-apple-macosx/release/pinaklean-cli" "./$APP_NAME-cli"

# Create minimal app bundle structure
echo "📦 Creating app bundle..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy files
cp "$APP_NAME.sh" "$APP_NAME.app/Contents/MacOS/$APP_NAME"
cp "$APP_NAME-cli" "$APP_NAME.app/Contents/Resources/pinaklean-cli"

# Create Info.plist
cat > "$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.pinaklean.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
EOF

# Move to release directory
cd ..
mv "PinakleanApp/$APP_NAME.app" "$RELEASE_DIR/"

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "$APP_NAME $VERSION" \
               -srcfolder "$APP_BUNDLE" \
               -ov \
               -format UDZO \
               "$RELEASE_DIR/$DMG_NAME"

# Generate signatures
echo "🔐 Generating SHA256 signatures..."
DMG_SHA256=$(shasum -a 256 "$RELEASE_DIR/$DMG_NAME" | cut -d' ' -f1)
APP_SHA256=$(shasum -a 256 "$APP_BUNDLE/Contents/MacOS/$APP_NAME" | cut -d' ' -f1)

# Clean up temporary files
rm -f "PinakleanApp/$APP_NAME.sh" "PinakleanApp/$APP_NAME-cli"

echo ""
echo "✅ Release created successfully!"
echo "==============================="
echo "📁 App Bundle: $APP_BUNDLE"
echo "💿 DMG File: $RELEASE_DIR/$DMG_NAME"
echo "📊 DMG SHA256: $DMG_SHA256"
echo "📊 App SHA256: $APP_SHA256"
echo "📏 Size: $(du -sh "$RELEASE_DIR/$DMG_NAME" | cut -f1)"
echo ""
echo "🎯 Next Steps:"
echo "1. Test the app: open $APP_BUNDLE"
echo "2. Test the DMG: open $RELEASE_DIR/$DMG_NAME"
echo "3. Create GitHub release with the DMG file"
echo "4. Share download link with users"
echo ""
echo "🚀 Ready for distribution!"