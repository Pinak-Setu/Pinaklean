#!/bin/bash
echo '🧪 PINAKLEAN SOTA COMPREHENSIVE TESTING'
echo '========================================'

# Test basic commands
echo '📋 Testing basic commands...'
swift run pinaklean-cli --help | grep -q 'pinaklean' && echo '✅ Help command: PASS' || echo '❌ Help command: FAIL'

# Test scan command
echo '📋 Testing scan commands...'
swift run pinaklean-cli scan | grep -q '📊 Scan Results' && echo '✅ Basic scan: PASS' || echo '❌ Basic scan: FAIL'

swift run pinaklean-cli scan --json | jq empty >/dev/null 2>&1 && echo '✅ JSON scan: PASS' || echo '❌ JSON scan: FAIL'

# Test clean command
echo '📋 Testing clean commands...'
swift run pinaklean-cli clean --dry-run | grep -q 'Dry.*Run' && echo '✅ Clean dry-run: PASS' || echo '❌ Clean dry-run: FAIL'

# Test config command
echo '📋 Testing config commands...'
swift run pinaklean-cli config --show | grep -q 'Safe mode' && echo '✅ Config show: PASS' || echo '❌ Config show: FAIL'

# Test backup command
echo '📋 Testing backup commands...'
swift run pinaklean-cli backup --list | grep -q 'Backup Registry' && echo '✅ Backup list: PASS' || echo '❌ Backup list: FAIL'

# Test error handling
echo '📋 Testing error handling...'
swift run pinaklean-cli invalidcommand 2>&1 | grep -q 'error\|Error' && echo '✅ Error handling: PASS' || echo '❌ Error handling: FAIL'

echo '🎯 TESTING COMPLETE - Review results above!'

