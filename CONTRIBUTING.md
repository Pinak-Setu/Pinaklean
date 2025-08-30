# Contributing to Pinaklean

Thank you for your interest in contributing to Pinaklean! We welcome contributions from developers of all skill levels.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch** from `main`
4. **Make your changes** and test thoroughly
5. **Submit a Pull Request** with a clear description

## 🛠️ Development Environment

### Prerequisites
- **macOS 14.0+**
- **Xcode 15.0+** or **Swift 5.9+**
- **Git** for version control

### Setup
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/Pinaklean.git
cd Pinaklean/PinakleanApp

# Install dependencies
swift package resolve

# Run tests to ensure everything works
swift test

# Build both CLI and GUI
swift build --product pinaklean-cli
swift build --product Pinaklean
```

## 🧪 Testing

### Running Tests
```bash
# All tests
swift test

# Specific test suites
swift test --filter SecurityTests
swift test --filter PerformanceTests
swift test --filter CLITests

# With code coverage
swift test --enable-code-coverage
```

### Test Coverage Requirements
- **95%+** overall test coverage
- **100%** coverage for new features
- All public APIs must have corresponding tests

## 📝 Code Style

### Swift Style Guidelines
- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistent code formatting
- Prefer `async/await` over completion handlers
- Use meaningful variable and function names

### Documentation
- Document all public APIs with Swift documentation comments
- Include usage examples for complex functions
- Explain any non-obvious behavior or edge cases

## 🔒 Security Considerations

### When making changes:
- Never bypass security guardrails without thorough review
- Consider the security implications of file system operations
- Test security features don't break existing functionality
- Report security issues privately to maintainers

### Security Testing
```bash
# Run security-focused tests
swift test --filter SecurityTests

# Manual security verification
./bin/pinaklean --safety-check
```

## 🚀 Submitting Changes

### Pull Request Process
1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Ensure all tests pass**
4. **Update CHANGELOG.md** if applicable
5. **Submit PR** with clear description

### PR Template
```
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Security Impact
- [ ] No security implications
- [ ] Security review required
- [ ] Breaking changes to security features
```

## 🎯 Areas for Contribution

### High Priority
- **Performance Optimization** - Improve scan/clean speeds
- **ML Model Training** - Better file safety prediction models
- **UI/UX Improvements** - Enhanced user experience
- **Cross-platform Support** - Linux/Windows compatibility

### Medium Priority
- **Additional Backup Providers** - More cloud storage options
- **Plugin System** - Extensibility for custom cleaners
- **Advanced Analytics** - Better usage insights
- **Accessibility** - Screen reader and keyboard navigation

### Low Priority
- **Documentation** - User guides and API docs
- **Internationalization** - Multi-language support
- **Themes** - Additional UI themes
- **Integration Tests** - More comprehensive testing

## 📞 Getting Help

- **Issues**: [GitHub Issues](https://github.com/Pinak-Setu/Pinaklean/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Pinak-Setu/Pinaklean/discussions)
- **Documentation**: [README.md](../README.md)

## 📄 License

By contributing to Pinaklean, you agree that your contributions will be licensed under the same Apache License 2.0 that covers the project.

Thank you for contributing to Pinaklean! 🎉
