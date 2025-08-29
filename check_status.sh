#!/bin/bash
echo "🚀 PINAKLEAN CI/CD STATUS CHECK"
echo "================================"

# Get workflow information
echo "📊 WORKFLOW RUN: 17321249479"
echo "🔗 https://github.com/Pinak-Setu/Pinaklean/actions/runs/17321249479"
echo ""

# Check status
STATUS_OUTPUT=$(gh run view 17321249479 --repo Pinak-Setu/Pinaklean 2>&1)

# Look for key indicators
if echo "$STATUS_OUTPUT" | grep -q "completed"; then
    echo "✅ WORKFLOW COMPLETED"
    
    if echo "$STATUS_OUTPUT" | grep -q "success\|successful"; then
        echo "🎉 STATUS: SUCCESS - ALL GREEN!"
        echo "✅ All tests passed successfully"
        echo ""
        echo "🏆 CI/CD VALIDATION COMPLETE"
        echo "✅ Ready for production deployment"
    elif echo "$STATUS_OUTPUT" | grep -q "failure\|failed"; then
        echo "❌ STATUS: FAILED - FIXES REQUIRED"
        echo "🔍 Analyzing failure details..."
        
        # Try to get job information
        echo "📋 FAILED JOBS:"
        echo "$STATUS_OUTPUT" | grep -E "(✗|failed|error)" | head -5
        
        echo ""
        echo "🔧 NEXT STEPS:"
        echo "   1. Review error logs at GitHub Actions"
        echo "   2. Fix identified issues"
        echo "   3. Push fixes and re-run CI/CD"
    else
        echo "⚠️ STATUS: COMPLETED WITH UNKNOWN RESULT"
    fi
elif echo "$STATUS_OUTPUT" | grep -q "running\|in_progress"; then
    echo "⏳ STATUS: STILL RUNNING"
    echo "🔄 Workflow is currently executing..."
    echo ""
    echo "📋 CURRENT JOBS:"
    echo "$STATUS_OUTPUT" | grep -E "(•|running)" | head -5
else
    echo "❓ STATUS: UNKNOWN"
    echo "Could not determine workflow status"
fi

echo ""
echo "🔗 Direct Link: https://github.com/Pinak-Setu/Pinaklean/actions/runs/17321249479"
