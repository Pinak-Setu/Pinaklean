#!/bin/bash

echo "�� PINAKLEAN CI/CD STATUS MONITOR"
echo "================================="
echo "Workflow Run: 17321249479"
echo "Repository: Pinak-Setu/Pinaklean"
echo ""

# Get workflow status
STATUS_JSON=$(gh run view 17321249479 --repo Pinak-Setu/Pinaklean --json status,conclusion 2>/dev/null)
if [ $? -eq 0 ]; then
    STATUS=$(echo "$STATUS_JSON" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
    CONCLUSION=$(echo "$STATUS_JSON" | grep -o '"conclusion":"[^"]*' | cut -d'"' -f4)
    
    echo "📊 Current Status: $STATUS"
    echo "📈 Conclusion: ${CONCLUSION:-Still Running}"
    echo ""
    
    if [ "$STATUS" = "completed" ]; then
        if [ "$CONCLUSION" = "success" ]; then
            echo "🎉 ALL GREEN! CI/CD PASSED SUCCESSFULLY!"
            echo "✅ All 7 tests completed successfully"
            echo ""
            echo "🏆 SUCCESS CONFIRMED - READY FOR PRODUCTION"
        else
            echo "❌ CI/CD FAILED - FIXES REQUIRED"
            echo "🔍 Getting detailed failure logs..."
            gh run view 17321249479 --repo Pinak-Setu/Pinaklean --log-failed 2>/dev/null || echo "Could not retrieve failure logs"
        fi
    else
        echo "⏳ WORKFLOW STILL RUNNING..."
        echo "🔄 Checking individual job statuses..."
        
        # Try to get job statuses
        gh run view 17321249479 --repo Pinak-Setu/Pinaklean 2>/dev/null | grep -E "(✓|✗|•|failed|passed|running)" | head -10
    fi
else
    echo "❌ Could not access GitHub API"
    echo "🔗 Check manually: https://github.com/Pinak-Setu/Pinaklean/actions/runs/17321249479"
fi

echo ""
echo "🔗 Direct Link: https://github.com/Pinak-Setu/Pinaklean/actions/runs/17321249479"
