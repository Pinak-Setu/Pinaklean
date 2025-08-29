#!/bin/bash

echo "🚀 PINAKLEAN CI/CD MONITOR - REAL TIME STATUS"
echo "============================================="

# Check GitHub Actions API
echo "📊 CHECKING GITHUB ACTIONS STATUS..."
curl -s "https://api.github.com/repos/Pinak-Setu/Pinaklean/actions/runs?per_page=1" | jq -r '.workflow_runs[0] | "Status: \(.status) | Conclusion: \(.conclusion) | URL: \(.html_url)"' 2>/dev/null || echo "❌ Cannot access GitHub API directly"

echo ""
echo "🔍 EXPECTED TEST RESULTS (7/7):"
echo "   1. 🔒 Security Audit: CodeQL + SwiftLint"
echo "   2. 🧪 Unit Tests: Core component tests"  
echo "   3. 🔗 Integration Tests: CLI + Engine integration"
echo "   4. ⚡ Performance Tests: Build speed validation"
echo "   5. 📏 Code Quality: Swift best practices"
echo "   6. 📚 Documentation: README validation"
echo "   7. 🚀 CI/CD Gates: Pipeline configuration"

echo ""
echo "⚠️  CRITICAL: ALL 7 MUST PASS FOR 'ALL GREEN'"
echo "💡 Check: https://github.com/Pinak-Setu/Pinaklean/actions"
