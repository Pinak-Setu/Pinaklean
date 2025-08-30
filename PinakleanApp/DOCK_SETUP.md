
# To add Pinaklean to your Dock permanently:
#
# Option 1: From Finder
# 1. Open Finder
# 2. Go to: /Users/abhijita/Projects/Pinaklean/PinakleanApp/build/release/
# 3. Drag "Pinaklean.app" to your Dock
#
# Option 2: Using Terminal
# Run this command:
# defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Users/abhijita/Projects/Pinaklean/PinakleanApp/build/release/Pinaklean.app</string><key>_CFURLStringType</key><integer>0</integer></dict><key>file-label</key><string>Pinaklean</string></dict><key>tile-type</key><string>file-tile</string></dict>"
# killall Dock
#
# This will add Pinaklean to your Dock with the custom app icon!
