## 🕐 Automated Hourly Cleaning

Pinaklean can automatically maintain your Mac with safe, scheduled cleaning:

### Installation

1. **Install the hourly cleaning system:**
   ```bash
   chmod +x scripts/install_hourly_clean.sh
   ./scripts/install_hourly_clean.sh
   ```

2. **Load the launchd agent:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.pinaklean.hourlyclean.plist
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
# Safety verification
./bin/pinaklean --safety-check

# Dry run testing
./bin/pinaklean --dry-run --categories all

# Performance testing
time ./bin/pinaklean --categories userCaches,logs
```

## 📊 Monitoring & Analytics

### Metrics Collection
Pinaklean tracks comprehensive metrics:
- **Daily Cleaning**: Items cleaned, space freed, duration
- **System Health**: CPU usage, memory, disk space
- **Performance**: Scan times, processing efficiency
- **Safety**: Operations blocked, risk assessments

### Analytics Dashboard
```bash
# View daily metrics
cat ~/.pinaklean/metrics.json | jq .daily

# View total statistics
cat ~/.pinaklean/metrics.json | jq .total

# Generate cleaning report
./scripts/generate_report.sh
```

### Log Analysis
```bash
# View recent cleaning activity
tail -50 ~/.pinaklean/hourly_clean.log

# Search for specific events
grep "SUCCESS\|ERROR" ~/.pinaklean/hourly_clean.log

# Analyze error patterns
grep "ERROR" ~/.pinaklean/hourly_clean.log | sort | uniq -c
```
