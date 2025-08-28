# 🧹 Pinaklean

> **Safe macOS cleanup toolkit for developers - Where Intelligence Meets Cleanliness**

[![CI/CD Pipeline](https://github.com/Pinak-Setu/Pinaklean/actions/workflows/ci.yml/badge.svg)](https://github.com/Pinak-Setu/Pinaklean/actions/workflows/ci.yml)
[![Test Coverage](https://codecov.io/gh/Pinak-Setu/Pinaklean/branch/main/graph/badge.svg)](https://codecov.io/gh/Pinak-Setu/Pinaklean)
[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014+-lightgrey.svg)](https://developer.apple.com/macos/)

**Pinaklean** is an intelligent, safe, and comprehensive disk cleanup utility designed specifically for macOS developers. It combines advanced safety mechanisms with powerful automation to help you maintain a clean and efficient development environment.

## ✨ Key Features

### 🛡️ Safety First
- **7-Layer Security Audit**: Comprehensive path validation, ownership checks, and process monitoring
- **Smart Safety Scoring**: ML-powered analysis of file deletion safety (0-100 scale)
- **System File Protection**: Extensive deny-list of critical system paths
- **Automatic Backups**: Cloud-based backups to iCloud, GitHub, IPFS, and more

### 🤖 Intelligence
- **ML-Powered Detection**: Smart detection of cache files, logs, and build artifacts
- **Duplicate Detection**: Perceptual hashing for finding duplicate files
- **Usage Pattern Learning**: Adapts to your cleaning preferences over time
- **Context-Aware Cleaning**: Understands file importance based on content and usage

### ⚡ Performance
- **Parallel Processing**: Concurrent file operations with optimal CPU utilization
- **Incremental Indexing**: Fast scans using SQLite-based change tracking
- **Memory Efficient**: Optimized for large file systems
- **Real-time Monitoring**: Live progress tracking and performance metrics

### 🎨 Modern UI
- **Glassmorphic Design**: Beautiful macOS-native interface with blur effects
- **Menu Bar Integration**: Quick access and status monitoring
- **Dark Mode Support**: Full dark/light theme compatibility
- **Responsive Layout**: Adaptive interface for different screen sizes

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/Pinak-Setu/Pinaklean.git
cd Pinaklean

# Build the project
swift build --configuration release

# Install CLI tool
cp .build/release/pinaklean-cli /usr/local/bin/pinaklean
```

### Basic Usage

```bash
# Interactive mode (recommended)
pinaklean

# Quick scan and clean
pinaklean auto

# Safe scan only
pinaklean scan --safe

# Aggressive mode (still protected by guardrails)
pinaklean clean --aggressive

# Dry run (preview only)
pinaklean --dry-run
```

### GUI Application

```bash
# Build and run GUI
xcodebuild -project Pinaklean.xcodeproj -scheme Pinaklean
open build/Release/Pinaklean.app
```

## 📋 Cleaning Categories

| Category | Description | Safety Level |
|----------|-------------|--------------|
| **System Caches** | macOS system caches | High Risk |
| **App Caches** | Application-specific caches | Medium Risk |
| **Developer Junk** | Xcode, Node.js, build artifacts | Low Risk |
| **Logs** | System and application logs | Low Risk |
| **Temporary Files** | System temp files | Very Low Risk |
| **Trash** | User trash contents | Very Low Risk |
| **Duplicates** | Duplicate files detection | Low Risk |

## 🔧 Configuration

### CLI Configuration
```bash
# Set backup provider
pinaklean config --backup-provider icloud

# Configure safety level
pinaklean config --safety-level paranoid

# Set parallel workers
pinaklean config --workers 8
```

### GUI Configuration
- Open Pinaklean app
- Navigate to Settings
- Configure preferences:
  - Glass effects toggle
  - Animation settings
  - Backup providers
  - Safety preferences
  - Notification settings

## 🏗️ Architecture

```
Pinaklean Ecosystem
├── CLI Tool (Swift Argument Parser)
├── GUI App (SwiftUI + Glassmorphic Design)
├── Core Engine (Swift Concurrency)
│   ├── SecurityAuditor (7-layer security)
│   ├── SmartDetector (ML-powered analysis)
│   ├── ParallelProcessor (Concurrent operations)
│   ├── IncrementalIndexer (SQLite-based tracking)
│   ├── RAGManager (Explainable decisions)
│   └── CloudBackupManager (Multi-provider backups)
└── Testing Infrastructure (95%+ coverage)
```

## 🧪 Testing & Quality

### Test Coverage
- **Unit Tests**: Core component functionality
- **Integration Tests**: End-to-end workflows
- **Security Tests**: Guardrail validation
- **Performance Tests**: Benchmarking and optimization
- **UI Tests**: Interface validation

### Running Tests
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter SecurityTests

# Generate coverage report
swift test --enable-code-coverage
```

### CI/CD Pipeline
Our comprehensive CI/CD pipeline includes:
- ✅ **Security Audit** (CodeQL, SwiftLint)
- ✅ **Multi-Xcode Testing** (Xcode 14.3, 15.0)
- ✅ **Integration Testing** (End-to-end workflows)
- ✅ **Performance Benchmarking**
- ✅ **Code Coverage** (95%+ target)
- ✅ **Documentation Generation**
- ✅ **Automated Deployment**

## 📊 Monitoring & Analytics

### Real-time Metrics
- CPU and memory usage
- Processing throughput
- File system statistics
- Backup status

### Performance Analytics
- Scan completion time
- Deletion success rate
- Storage space recovered
- Error rate monitoring

## 🔒 Security & Safety

### Guardrails
1. **System Path Protection**: 40+ critical system paths blocked
2. **File Ownership Validation**: Root/system file detection
3. **Process Monitoring**: Active file usage detection
4. **Signature Verification**: Code-signed file validation
5. **Size Limits**: Large file warnings and protection
6. **Type Filtering**: Dangerous file extension blocking

### Security Features
- **Encrypted Backups**: AES-256 encryption for all backups
- **Secure Key Storage**: Keychain integration for credentials
- **Audit Logging**: Comprehensive operation logging
- **Permission Validation**: macOS permission system integration

## ☁️ Backup & Recovery

### Supported Providers
- **iCloud Drive** (5GB free)
- **GitHub** (Gists + Releases)
- **IPFS** (Decentralized storage)
- **Local NAS** (Network storage)
- **WebDAV** (Self-hosted)

### Backup Features
- **Incremental Backups**: Only changed files
- **Compression**: Zlib compression for efficiency
- **Deduplication**: Block-level deduplication
- **Retention Policies**: Configurable retention periods
- **Multi-provider Sync**: Simultaneous backup to multiple providers

## 📚 Documentation

- **[Installation Guide](docs/installation.md)**
- **[User Manual](docs/user-manual.md)**
- **[API Documentation](docs/api/)**
- **[Contributing Guide](docs/contributing.md)**
- **[Security Policy](security/SECURITY-IRONCLAD.md)**

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/contributing.md) for details.

### Development Setup
```bash
# Clone and setup
git clone https://github.com/Pinak-Setu/Pinaklean.git
cd Pinaklean

# Install dependencies
swift package resolve

# Run tests
swift test

# Build GUI
xcodebuild -project Pinaklean.xcodeproj -scheme Pinaklean
```

### Code Quality
- **SwiftLint**: Enforced code style
- **Test Coverage**: 95%+ requirement
- **Security Audit**: Automated vulnerability scanning
- **Documentation**: Required for all public APIs

## 🐛 Issues & Support

- **Bug Reports**: [GitHub Issues](https://github.com/Pinak-Setu/Pinaklean/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/Pinak-Setu/Pinaklean/discussions)
- **Security Issues**: [Security Policy](security/SECURITY-IRONCLAD.md)
- **Documentation**: [GitHub Wiki](https://github.com/Pinak-Setu/Pinaklean/wiki)

## 📄 License

**Apache License 2.0** - See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Apple Swift and SwiftUI teams
- macOS developer community
- Open source contributors

---

**Made with ❤️ for developers, by developers**

*"Pinaklean: Where Intelligence Meets Cleanliness"* 🚀✨
