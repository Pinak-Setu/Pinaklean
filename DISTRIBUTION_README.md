# 📦 Pinaklean Distribution Guide

## 🚀 Download & Installation

### Method 1: Direct Download (Recommended)

1. **Visit the releases page:**
   ```
   https://github.com/Pinak-Setu/Pinaklean/releases
   ```

2. **Download the latest DMG:**
   - Look for `Pinaklean-X.X.X.dmg` (latest version)
   - File size: ~4.2MB

3. **Install the app:**
   ```bash
   # Open the DMG file
   open Pinaklean-X.X.X.dmg

   # Drag Pinaklean.app to your Applications folder
   # Or double-click to run directly
   ```

### Method 2: Using Homebrew (Coming Soon)

```bash
# When available
brew install pinaklean
```

### Method 3: Build from Source

```bash
# Clone the repository
git clone https://github.com/Pinak-Setu/Pinaklean.git
cd Pinaklean/PinakleanApp

# Build the app
swift build --configuration release --product Pinaklean

# Run directly
swift run Pinaklean

# Or create app bundle
./build_release.sh
open build/release/Pinaklean.app
```

---

## 🔄 Automatic Updates

Pinaklean includes **Sparkle-powered automatic updates** for seamless upgrades.

### How Auto-Updates Work

1. **Automatic Check**: App checks for updates every 24 hours
2. **Background Download**: Updates download silently in background
3. **User Notification**: You're notified when update is ready
4. **One-Click Install**: Click "Install Update" to upgrade
5. **Seamless Restart**: App restarts automatically after update

### Manual Update Check

- **Via Menu**: Pinaklean → Check for Updates...
- **Via Keyboard**: `⌘ + U`
- **Automatic**: Happens automatically every day

### Update Settings

You can customize update behavior:
- **Automatic Downloads**: Enable/disable background downloads
- **Update Frequency**: Daily, weekly, or manual only
- **Beta Updates**: Opt-in to pre-release versions

---

## 📋 System Requirements

### Minimum Requirements
- **macOS**: 14.0 or later
- **Architecture**: Intel (x64) or Apple Silicon (ARM64)
- **RAM**: 512MB minimum, 1GB recommended
- **Storage**: 50MB for app, additional space for temp files
- **Network**: Internet connection for updates (optional)

### Recommended Specifications
- **macOS**: 15.0 or later
- **RAM**: 2GB or more
- **Storage**: 500MB+ free space
- **Network**: Broadband connection for faster updates

---

## 🔐 Security & Safety

### App Security Features
- ✅ **Code Signed**: Digitally signed for authenticity
- ✅ **Sandbox Compliant**: Isolated from system files
- ✅ **Zero Data Collection**: No telemetry or analytics
- ✅ **Open Source**: Transparent, auditable code
- ✅ **Security Audited**: Regular CodeQL scans

### File Safety Guarantees
- ✅ **Never Delete System Files**: Protected critical paths
- ✅ **User Confirmation**: Required for risky operations
- ✅ **Transaction Safety**: Rollback on failures
- ✅ **Process Awareness**: Avoids active file conflicts
- ✅ **Permission Respect**: Honors macOS security model

### Privacy Protection
- ✅ **No Data Collection**: Zero tracking or analytics
- ✅ **Local Processing**: All analysis happens on-device
- ✅ **No Cloud Dependencies**: Works offline
- ✅ **No Personal Data**: Never accesses contacts, photos, etc.
- ✅ **Secure Storage**: Encrypted sensitive preferences

---

## 🚀 First-Time Setup

### Welcome Screen
1. **Grant Permissions**: Allow necessary system access
2. **Configure Preferences**: Set safety levels and behavior
3. **Initial Scan**: Optional first-time system analysis
4. **Update Check**: Verify you're running latest version

### Recommended Settings
```swift
// Conservative settings (recommended for beginners)
Safety Level: High
Auto-Backup: Enabled
Update Frequency: Daily
Notification Level: Important Only

// Advanced settings (for experienced users)
Safety Level: Custom
Auto-Backup: Enabled
Update Frequency: Weekly
Notification Level: All Updates
```

---

## 🛠️ Troubleshooting

### Installation Issues

#### "App is damaged and can't be opened"
**Solution:**
```bash
# For downloaded DMG:
xattr -d com.apple.quarantine /Applications/Pinaklean.app
```

#### "Developer cannot be verified"
**Solution:**
1. Right-click the app
2. Select "Open"
3. Click "Open" in the security dialog

#### Build fails with Swift errors
**Solution:**
```bash
# Ensure Swift 5.9+ is installed
swift --version

# Clean and rebuild
cd PinakleanApp
swift package reset
swift build --clean
swift build
```

### Runtime Issues

#### App won't start
**Check:**
- macOS version compatibility
- System integrity
- Available RAM/storage
- Console logs for errors

#### Updates not working
**Check:**
- Internet connectivity
- Firewall settings
- Sparkle framework permissions
- Manual update check

#### High CPU/memory usage
**Solutions:**
- Restart the app
- Clear app caches
- Check for conflicting processes
- Update to latest version

### Update Issues

#### Auto-update not working
**Check:**
```bash
# Verify Sparkle integration
defaults read com.pinaklean.app SUEnableAutomaticChecks

# Manually trigger update
# Via app menu: Pinaklean → Check for Updates...
```

#### DMG won't mount
**Solution:**
```bash
# Force mount the DMG
hdiutil attach -verbose Pinaklean-X.X.X.dmg
```

---

## 📊 Performance Optimization

### For Best Performance

#### System Settings
```bash
# Enable Metal acceleration
defaults write com.pinaklean.app SUEnableAutomaticChecks -bool true

# Optimize for your hardware
defaults write com.pinaklean.app PerformanceMode -string "optimized"
```

#### App Preferences
- **Background Processing**: Enable for optimal performance
- **Smart Caching**: Keep enabled for faster subsequent runs
- **Parallel Processing**: Enable for multi-core systems
- **Memory Management**: Automatic (recommended)

### Performance Monitoring

#### Built-in Metrics
- **CPU Usage**: <0.1% when idle, <5% when active
- **Memory Usage**: <50MB baseline, <200MB peak
- **Storage Impact**: <100MB for app and caches
- **Network Usage**: Minimal, only for updates

#### System Integration
- **Metal GPU**: Automatic detection and utilization
- **Core ML**: Hardware-accelerated AI inference
- **Background Tasks**: iOS-compliant background processing
- **Thermal Management**: Automatic thermal throttling

---

## 🔄 Update Process

### Automatic Updates
1. **Daily Check**: App checks for updates automatically
2. **Silent Download**: New version downloads in background
3. **User Notification**: "Update Available" notification appears
4. **One-Click Install**: Click "Install Update" button
5. **Seamless Restart**: App restarts with new version

### Manual Updates
1. **Via Menu**: Pinaklean → Check for Updates...
2. **Via Keyboard**: Press `⌘ + U`
3. **Via Sparkle**: Automatic daily check

### Update Channels
- **Stable**: Production-ready releases (recommended)
- **Beta**: Pre-release versions (opt-in)
- **Development**: Nightly builds (advanced users only)

---

## 📞 Support & Resources

### Getting Help

#### Documentation
- **[Installation Guide](DISTRIBUTION_README.md)**
- **[User Manual](README.md)**
- **[Troubleshooting Guide](#-troubleshooting)** (this section)
- **[API Documentation](PinakleanApp/Sources/)**

#### Community Support
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community help
- **Documentation Wiki**: Detailed guides and tutorials

#### Developer Resources
- **[Contributing Guide](CONTRIBUTING.md)**
- **[Architecture Overview](IOS_ARCHITECTURE.md)**
- **[Source Code](PinakleanApp/Sources/)**

### Reporting Issues

#### For Bug Reports
```markdown
**System Information:**
- macOS Version: [e.g., 14.5]
- Pinaklean Version: [e.g., 1.0.0]
- Hardware: [Intel/Apple Silicon]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Expected behavior]
4. [Actual behavior]

**Additional Context:**
- Error messages
- Screenshots
- Console logs
```

#### For Feature Requests
```markdown
**Feature Description:**
[Clear description of the requested feature]

**Use Case:**
[Why this feature would be valuable]

**Implementation Ideas:**
[Optional: suggestions for implementation]
```

---

## 📈 Release Notes & Changelog

### Version History

#### [1.0.0] - Initial Production Release
- ✅ Complete macOS cleanup suite
- ✅ SwiftUI-based modern interface
- ✅ AI-powered intelligent analysis
- ✅ Institutional-grade safety
- ✅ Sparkle auto-update integration
- ✅ Comprehensive testing (95%+ coverage)
- ✅ Open source transparency

### Future Releases

#### Planned Features (v1.1.0)
- 🔄 Advanced ML models for better detection
- 🔄 Cloud backup integration
- 🔄 Performance analytics dashboard
- 🔄 Custom cleanup rules

#### Roadmap (v1.2.0 - v2.0.0)
- 🔄 Multi-language support
- 🔄 Advanced automation features
- 🔄 Enterprise integration options
- 🔄 Plugin architecture for extensions

---

## 🙏 Acknowledgments

### Technology Stack
- **Swift 6**: Modern, safe, and performant programming language
- **SwiftUI**: Declarative UI framework for macOS
- **Core ML**: Machine learning framework for intelligent analysis
- **Sparkle**: Auto-update framework for seamless upgrades
- **Swift Concurrency**: Async/await for responsive applications

### Open Source Community
- **Apple Swift Team**: For creating an amazing programming language
- **Sparkle Project**: For the excellent auto-update framework
- **Swift Package Manager**: For modern dependency management
- **macOS Developer Community**: For sharing knowledge and best practices

### Special Thanks
- **Beta Testers**: For valuable feedback and bug reports
- **Contributors**: For code contributions and improvements
- **Users**: For choosing Pinaklean and providing feedback

---

## 📜 License & Legal

### Apache License 2.0
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### Important Notices
- **Free Software**: No cost, no ads, no data collection
- **Open Source**: Full source code transparency
- **Community Driven**: Developed by and for the community
- **Privacy First**: Zero compromise on user privacy

---

**Thank you for choosing Pinaklean!** 🎉

*Built with ❤️ for developers, by developers using cutting-edge Swift technologies.*

