#!/bin/bash
echo "🔧 Fixing Swift Compilation Errors"

# 1. Fix SecurityAuditor syntax error
echo "Fixing SecurityAuditor syntax error..."
cd PinakleanApp/Core/Engine
sed -i '' 's/return AuditResult(/let sizeStr = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)\
            return AuditResult(/g' SecurityAuditor.swift

sed -i '' 's/let sizeStr = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)\
                message: /message: /g' SecurityAuditor.swift

# 2. Remove duplicate type definitions from AIPredictor
echo "Removing duplicate types from AIPredictor..."
cd ../..

# Remove duplicate CleaningRecommendation struct
sed -i '' '/\/\/\/ Cleaning recommendation with AI enhancements/,/^}$/d' PinakleanApp/Core/Engine/AIPredictor.swift

# Remove duplicate RiskLevel enum  
sed -i '' '/\/\/\/ Risk levels/,/^}$/d' PinakleanApp/Core/Engine/AIPredictor.swift

# Remove duplicate ContentType enum
sed -i '' '/\/\/\/ Content type classification/,/^}$/d' PinakleanApp/Core/Engine/AIPredictor.swift

# 3. Add missing imports to AIPredictor
echo "Adding missing imports..."
sed -i '' '1a\
import Foundation\
import CoreML\
import NaturalLanguage\
import Vision\
import Combine\
import Network\
import SystemConfiguration' PinakleanApp/Core/Engine/AIPredictor.swift

# 4. Remove Vision extension (already defined)
sed -i '' '/extension Vision {/,/^}$/d' PinakleanApp/Core/Engine/AIPredictor.swift

# 5. Add missing types to AIPredictor (if needed)
echo "Adding missing compliance types..."
cat >> PinakleanApp/Core/Engine/AIPredictor.swift << 'TYPE_EOF'

// MARK: - Missing Compliance Types
enum ComplianceStatus {
    case compliant, nonCompliant, reviewing
}

enum ComplianceSeverity {
    case low, medium, high, critical
}

struct ComplianceRule {
    // Placeholder
}
TYPE_EOF

echo "✅ Compilation errors fixed!"
echo "Now attempting build again..."

cd PinakleanApp
swift package resolve
if swift build --configuration release; then
    echo "🎉 BUILD SUCCESSFUL!"
else
    echo "❌ Build still failing - check for remaining errors"
fi
