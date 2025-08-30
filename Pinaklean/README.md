## 🕐 Automated Maintenance Features

**Available in v1.0.0:**
Pinaklean provides comprehensive automated maintenance capabilities:

### Installation

#### Method 1: Swift Package Manager
```bash
# Clone and build
git clone https://github.com/Pinak-Setu/Pinaklean.git
cd Pinaklean/PinakleanApp

# Build the CLI tool
swift build --product pinaklean-cli --configuration release

# Install globally (optional)
sudo cp .build/release/pinaklean-cli /usr/local/bin/pinaklean
```

#### Method 2: Download Pre-built Binary
```bash
# From GitHub Releases
# https://github.com/Pinak-Setu/Pinaklean/releases/tag/v1.0.0

# Make executable
chmod +x pinaklean-cli
./pinaklean-cli --help
```

### Automated Maintenance Setup

1. **Install the maintenance system:**
   ```bash
   # Create maintenance directory
   mkdir -p ~/.pinaklean

   # Copy maintenance scripts (if available)
   # cp scripts/hourly_clean.sh ~/.pinaklean/
   # chmod +x ~/.pinaklean/hourly_clean.sh
   ```

2. **Configure automated cleaning:**
   ```bash
   # Set up launchd agent (example)
   # cp scripts/com.pinaklean.hourlyclean.plist ~/Library/LaunchAgents/
   # launchctl load ~/Library/LaunchAgents/com.pinaklean.hourlyclean.plist
   ```

### Features
- **Smart Scheduling**: Avoids peak hours (9 AM - 6 PM weekdays)
- **Resource Aware**: Only runs when system is idle and has sufficient resources
- **Conservative Cleaning**: Uses safe categories during peak hours
- **Notifications**: macOS notifications for cleaning completion
- **Logging**: Comprehensive logs in `~/.pinaklean/hourly_clean.log`

### Manual Testing
```bash
# Test the hourly cleaning script
./scripts/hourly_clean.sh

# View logs
tail -f ~/.pinaklean/hourly_clean.log
```

### Monitoring
- **Status Check**: `launchctl list | grep pinaklean`
- **Stop Service**: `launchctl unload ~/Library/LaunchAgents/com.pinaklean.hourlyclean.plist`
- **Metrics**: View daily cleaning metrics in `~/.pinaklean/metrics.json`

## 🔔 Notification System

Pinaklean includes comprehensive notifications for all operations:

### Notification Types
- **Cleanup Complete**: When manual cleaning finishes
- **Hourly Maintenance**: Automatic cleaning notifications
- **Safety Alerts**: When operations are blocked for safety
- **Low Disk Space**: Warnings when storage is low
- **Error Alerts**: When operations encounter issues

### Notification Settings
Configure in the GUI app or via command line:
```bash
pinaklean config notifications --enable hourlyMaintenance,safetyAlerts
pinaklean config notifications --disable errorAlerts
```

## 🧪 Testing & Quality Assurance

### Running Tests
```bash
# All tests
swift test

# Specific test suites
swift test --filter SecurityTests
swift test --filter PerformanceTests
swift test --filter IntegrationTests

# With code coverage
swift test --enable-code-coverage
```

### Test Coverage
- **Security Tests**: Critical path protection, guardrails
- **Performance Tests**: Benchmarks, memory usage, scalability
- **Integration Tests**: End-to-end workflows
- **Unit Tests**: Component functionality

### CI/CD Pipeline
Our comprehensive CI/CD pipeline ensures:
- ✅ Security audit (CodeQL, SwiftLint)
- ✅ Multi-Xcode testing (14.3, 15.0)
- ✅ Performance benchmarking
- ✅ 95%+ test coverage
- ✅ Automated deployment

### Manual Testing Commands
```bash
# Build the CLI tool first
cd PinakleanApp
swift build --product pinaklean-cli --configuration release

# Safety verification (dry-run)
./.build/release/pinaklean-cli clean --dry-run

# Scan testing
./.build/release/pinaklean-cli scan --safe --verbose

# Performance testing
time ./.build/release/pinaklean-cli scan --safe

# Configuration testing
./.build/release/pinaklean-cli config --show

# Help system
./.build/release/pinaklean-cli --help
./.build/release/pinaklean-cli scan --help
./.build/release/pinaklean-cli clean --help
```

## 📊 Monitoring & Analytics

### Metrics Collection (v1.0.0)
Pinaklean provides real-time performance metrics:

#### Current Metrics Available:
- **Processing Statistics**: Files scanned, processing time
- **Safety Metrics**: Operations blocked, safety score distributions
- **Performance Data**: CPU usage, memory consumption
- **System Health**: Disk space analysis, file counts

#### Viewing Metrics:
```bash
# Real-time performance during scanning
./.build/release/pinaklean-cli scan --safe --verbose

# Configuration and system info
./.build/release/pinaklean-cli config --show

# Performance benchmarking
time ./.build/release/pinaklean-cli scan --safe
```

#### Future Analytics Features:
- **Daily Cleaning Reports** (planned for v1.1.0)
- **Trend Analysis** (planned for v1.2.0)
- **Automated Alerts** (planned for v1.3.0)
- **Historical Data** (planned for v1.4.0)

### Log Analysis
```bash
# View CLI output with verbose logging
./.build/release/pinaklean-cli scan --safe --verbose

# Debug information
./.build/release/pinaklean-cli --help

# Configuration details
./.build/release/pinaklean-cli config --show
```

### Roadmap for Advanced Analytics:
- ✅ **Basic Performance Metrics** (v1.0.0)
- 🔄 **Daily Cleaning Reports** (v1.1.0)
- 🔄 **Trend Analysis Dashboard** (v1.2.0)
- 🔄 **Automated Alert System** (v1.3.0)
- 🔄 **Historical Data Storage** (v1.4.0)
