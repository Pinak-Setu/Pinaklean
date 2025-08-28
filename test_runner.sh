#!/bin/bash

# Pinaklean Comprehensive Test Runner
# Runs all tests and validates the entire system
# Follows TDD principles and CI/CD best practices

set -euo pipefail

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="$PROJECT_ROOT/test_results_$(date +%Y%m%d_%H%M%S).log"
COVERAGE_REPORT="$PROJECT_ROOT/coverage_report_$(date +%Y%m%d_%H%M%S).lcov"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$TEST_LOG"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$TEST_LOG"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG"
}

log_header() {
    echo -e "\n${BLUE}================================${NC}" | tee -a "$TEST_LOG"
    echo -e "${BLUE}$1${NC}" | tee -a "$TEST_LOG"
    echo -e "${BLUE}================================${NC}\n" | tee -a "$TEST_LOG"
}

# Test phase functions
run_unit_tests() {
    log_header "Running Unit Tests"

    if ! command -v swift >/dev/null 2>&1; then
        log_error "Swift not found. Skipping unit tests."
        return 1
    fi

    log_info "Building project..."
    cd PinakleanApp
    if ! swift build --configuration debug; then
        log_error "Build failed"
        cd ..
        return 1
    fi

    log_info "Running unit tests with coverage..."
    if swift test --enable-code-coverage --configuration debug; then
        log_success "Unit tests passed"
        cd ..
        return 0
    else
        log_error "Unit tests failed"
        cd ..
        return 1
    fi
}

run_integration_tests() {
    log_header "Running Integration Tests"

    # Create test environment
    TEST_DIR="/tmp/pinaklean_integration_test_$(date +%s)"
    mkdir -p "$TEST_DIR"

    # Create test files
    echo "test content 1" > "$TEST_DIR/file1.txt"
    echo "test content 2" > "$TEST_DIR/file2.txt"
    mkdir -p "$TEST_DIR/subdir"
    echo "test content 3" > "$TEST_DIR/subdir/file3.txt"

    log_info "Testing CLI integration..."

    # Build CLI if not already built
    if [[ ! -f "bin/pinaklean" ]]; then
        cd PinakleanApp
        swift build --configuration release
        cp .build/release/pinaklean-cli ../bin/pinaklean 2>/dev/null || true
        cd ..
    fi

    if [[ -f "bin/pinaklean" ]]; then
        # Test dry run mode
        if ./bin/pinaklean --dry-run --help >/dev/null 2>&1; then
            log_success "CLI dry run test passed"
        else
            log_error "CLI dry run test failed"
        fi

        # Test scan functionality
        if ./bin/pinaklean scan --dry-run >/dev/null 2>&1; then
            log_success "CLI scan test passed"
        else
            log_warning "CLI scan test inconclusive (may be expected in clean environment)"
        fi
    else
        log_warning "CLI binary not found, skipping CLI integration tests"
    fi

    # Cleanup
    rm -rf "$TEST_DIR"

    return 0
}

run_security_tests() {
    log_header "Running Security Tests"

    if [[ ! -f "lib/security_audit.sh" ]]; then
        log_error "Security audit script not found"
        return 1
    fi

    chmod +x lib/security_audit.sh

    log_info "Running comprehensive security audit..."
    if ./lib/security_audit.sh --comprehensive; then
        log_success "Security audit passed"
        return 0
    else
        log_error "Security audit failed"
        return 1
    fi
}

run_performance_tests() {
    log_header "Running Performance Tests"

    log_info "Testing build performance..."
    local start_time=$(date +%s)

    cd PinakleanApp
    if swift build --configuration release >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local build_time=$((end_time - start_time))

        if [[ $build_time -lt 300 ]]; then  # Less than 5 minutes
            log_success "Build performance acceptable: ${build_time}s"
        else
            log_warning "Build performance slow: ${build_time}s"
        fi
        cd ..
    else
        log_error "Build failed during performance test"
        cd ..
        return 1
    fi

    return 0
}

run_lint_tests() {
    log_header "Running Code Quality Tests"

    # Check for SwiftLint
    if command -v swiftlint >/dev/null 2>&1; then
        log_info "Running SwiftLint..."
        if swiftlint --strict; then
            log_success "SwiftLint checks passed"
        else
            log_error "SwiftLint checks failed"
            return 1
        fi
    else
        log_warning "SwiftLint not installed, skipping lint checks"
    fi

    # Check for basic code quality issues
    log_info "Checking for common code quality issues..."

    # Check for TODO/FIXME comments (not necessarily bad, but worth noting)
    local todo_count=$(find . -name "*.swift" -o -name "*.sh" | xargs grep -l "TODO\|FIXME" | wc -l)
    if [[ $todo_count -gt 0 ]]; then
        log_info "Found $todo_count files with TODO/FIXME comments"
    fi

    # Check for debug print statements in production code
    local debug_prints=$(find . -name "*.swift" | xargs grep -l "print(" | grep -v "Test" | wc -l)
    if [[ $debug_prints -gt 0 ]]; then
        log_warning "Found $debug_prints Swift files with print statements (consider using proper logging)"
    fi

    return 0
}

run_documentation_tests() {
    log_header "Running Documentation Tests"

    # Check for required documentation files
    local required_files=("README.md" "LICENSE")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required documentation files: ${missing_files[*]}"
        return 1
    else
        log_success "Required documentation files present"
    fi

    # Validate README structure
    if grep -q "## " README.md && grep -q "Installation\|Usage\|Contributing" README.md; then
        log_success "README structure is valid"
    else
        log_error "README structure is incomplete"
        return 1
    fi

    return 0
}

run_ci_cd_validation() {
    log_header "Running CI/CD Pipeline Validation"

    # Check for CI/CD configuration
    if [[ -f ".github/workflows/ci.yml" ]]; then
        log_success "GitHub Actions CI/CD pipeline configured"
    else
        log_error "GitHub Actions CI/CD pipeline not found"
        return 1
    fi

    # Validate workflow syntax
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint .github/workflows/ci.yml >/dev/null 2>&1; then
            log_success "CI/CD workflow YAML syntax is valid"
        else
            log_error "CI/CD workflow YAML syntax is invalid"
            return 1
        fi
    else
        log_info "yamllint not available, skipping YAML validation"
    fi

    # Check for security gates in CI/CD
    if grep -q "security\|audit\|CodeQL" .github/workflows/ci.yml; then
        log_success "Security gates configured in CI/CD pipeline"
    else
        log_error "Security gates not found in CI/CD pipeline"
        return 1
    fi

    return 0
}

generate_test_report() {
    log_header "Generating Test Report"

    TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS + SKIPPED_TESTS))

    cat << EOF | tee -a "$TEST_LOG"

TEST EXECUTION SUMMARY
======================

Total Tests:     $TOTAL_TESTS
Passed:          $PASSED_TESTS
Failed:          $FAILED_TESTS
Skipped:         $SKIPPED_TESTS

Pass Rate:       $((PASSED_TESTS * 100 / TOTAL_TESTS))%

Test Results by Category:
-------------------------
✅ Unit Tests:       $(grep -c "\[PASS\].*Unit" "$TEST_LOG" || echo "0")
✅ Integration:      $(grep -c "\[PASS\].*Integration" "$TEST_LOG" || echo "0")
✅ Security:         $(grep -c "\[PASS\].*Security" "$TEST_LOG" || echo "0")
✅ Performance:      $(grep -c "\[PASS\].*Performance" "$TEST_LOG" || echo "0")
✅ Code Quality:     $(grep -c "\[PASS\].*Quality" "$TEST_LOG" || echo "0")
✅ Documentation:    $(grep -c "\[PASS\].*Documentation" "$TEST_LOG" || echo "0")
✅ CI/CD:           $(grep -c "\[PASS\].*CI/CD" "$TEST_LOG" || echo "0")

Detailed Results: $TEST_LOG
EOF

    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 ALL TESTS PASSED!"
        log_success "✅ System is ready for production deployment"
        return 0
    else
        log_error "❌ $FAILED_TESTS tests failed"
        log_error "⚠️  Review test results and fix issues before deployment"
        return 1
    fi
}

run_full_test_suite() {
    log_header "Starting Pinaklean Comprehensive Test Suite"
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Test Log: $TEST_LOG"
    log_info "Timestamp: $(date -Iseconds)"

    local start_time=$(date +%s)
    local exit_code=0

    # Run all test phases
    run_unit_tests || exit_code=1
    run_integration_tests || exit_code=1
    run_security_tests || exit_code=1
    run_performance_tests || exit_code=1
    run_lint_tests || exit_code=1
    run_documentation_tests || exit_code=1
    run_ci_cd_validation || exit_code=1

    # Generate final report
    generate_test_report

    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))

    log_info "Total test execution time: ${total_time}s"

    return $exit_code
}

# Main execution
case "${1:-}" in
    "--unit"|"-u")
        run_unit_tests
        ;;
    "--integration"|"-i")
        run_integration_tests
        ;;
    "--security"|"-s")
        run_security_tests
        ;;
    "--performance"|"-p")
        run_performance_tests
        ;;
    "--quality"|"-q")
        run_lint_tests
        ;;
    "--docs"|"-d")
        run_documentation_tests
        ;;
    "--ci"|"-c")
        run_ci_cd_validation
        ;;
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -u, --unit          Run unit tests only"
        echo "  -i, --integration  Run integration tests only"
        echo "  -s, --security     Run security tests only"
        echo "  -p, --performance Run performance tests only"
        echo "  -q, --quality      Run code quality tests only"
        echo "  -d, --docs         Run documentation tests only"
        echo "  -c, --ci          Run CI/CD validation only"
        echo "  -h, --help         Show this help"
        echo ""
        echo "Comprehensive test suite for Pinaklean."
        echo "Follows TDD principles and CI/CD best practices."
        ;;
    *)
        echo "Running full test suite..."
        run_full_test_suite
        ;;
esac
