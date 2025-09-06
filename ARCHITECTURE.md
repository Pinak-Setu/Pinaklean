# 🏛️ Pinaklean: Complete System Architecture

## 1. Overview & Guiding Principles

Pinaklean is an intelligent, safe, and comprehensive disk cleanup utility for Apple ecosystems. It is engineered to exceed professional-grade capabilities with institutional-grade safety standards.

### Vision
> "Intelligence that exceeds human capability in storage optimization, with safety that surpasses institutional standards."

### Core Architectural Principles
- **🛡️ Safety-First Design**: Every operation is designed with a primary focus on data integrity and system stability. Zero data loss is the most critical requirement.
- **🤖 Intelligence-Driven**: The system leverages a multi-layer AI architecture to make smart, context-aware decisions, moving beyond simple heuristics.
- **⚡ Invisible Performance**: The application is engineered to have a negligible impact on system resources, ensuring it runs seamlessly in the background without affecting the user's workflow.
- **🔒 Privacy-by-Design**: All analysis and processing happen on-device. No user data is ever collected or transmitted, ensuring absolute privacy.
- **🎨 Revolutionary UX**: The user experience is designed to be intuitive, adaptive, and emotionally intelligent, transforming a utility task into a seamless interaction.

---

## 2. Ecosystem Architecture

The Pinaklean ecosystem is composed of several components that share a common core engine, ensuring consistent logic and safety across all user-facing clients.

```
┌─────────────────────────────────────────────────────────┐
│                    Pinaklean Ecosystem                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   macOS GUI  │  │   iOS App    │  │   CLI Tool   │  │
│  │  (SwiftUI)   │  │  (SwiftUI)   │  │   (Swift)    │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│  ┌──────┴──────────────────┴──────────────────┴──────┐  │
│  │            Core Engine (Shared Framework)          │  │
│  │                   (PinakleanCore)                   │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ • Security Audit    • ML Detection   • Parallel   │  │
│  │ • Backup Manager    • RAG System     • Indexer    │  │
│  │ • Storage Forecast  • Deduplication  • Analytics  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Components
- **`Pinaklean.app` (macOS GUI)**: A rich, interactive application for macOS featuring advanced visualizations and a "Sentient Interface".
- **`Pinaklean iOS` (iPhone GUI)**: A revolutionary iPhone cleanup app designed for autonomous operation within the strict confines of the iOS sandbox.
- **`pinaklean-cli` (macOS CLI)**: A powerful command-line tool for developers and power users, enabling scripting and automation.
- **`PinakleanCore` (Shared Framework)**: The heart of the ecosystem. A SwiftPM framework containing all the core logic for scanning, cleaning, security, and intelligence.

---

## 3. Shared Core Engine (`PinakleanCore`)

This shared framework ensures that all Pinaklean clients operate with the same high standards of safety, intelligence, and performance.

```swift
// PinakleanCore.framework
public protocol CleaningEngine {
    func scan() async throws -> [CleanableItem]
    func clean(_ items: [CleanableItem]) async throws -> CleanResult
    func audit(_ items: [CleanableItem]) -> SecurityAuditResult
}

public struct PinakleanCore: CleaningEngine {
    let security: SecurityAuditor
    let intelligence: IntelligenceEngine
    let performance: PerformanceEngine
    let dataManager: DataManager
    // ... implementation
}
```

### Core Modules

#### 🛡️ Security Auditor
A 7-layer validation system that assesses risk for every file operation.
- **Guardrails**: Protects over 40 critical system paths.
- **Safety Scoring**: An ML-powered 0-100 scale risk assessment.
- **Validation**: Checks file ownership, active processes, and code signatures.
- **Risk Levels**: Classifies risk from `minimal` (safe for auto-clean) to `critical` (never delete).

#### 🤖 Intelligence Engine
Combines multiple AI techniques for smart detection and decision-making.
- **SmartDetector**: Uses Core ML models and heuristic fallbacks to identify junk files.
- **Duplicate Detection**: Employs perceptual hashing for finding similar images and videos, and byte-level checks for other files.
- **Predictive Forecasting**: Analyzes storage trends to predict future needs.
- **RAG System**: Provides explainable AI, detailing why a file is recommended for deletion.

#### ⚡ Performance Engine
Engineered for maximum speed with minimal system impact.
- **ParallelProcessor**: Uses Swift Concurrency (`async/await`, `TaskGroup`) to perform file operations concurrently, optimized for the system's processor count.
- **IncrementalIndexer**: Leverages a SQLite database (via GRDB) to track file system changes, making subsequent scans near-instantaneous.

#### 💾 Data Manager
- **CloudBackupManager**: Manages automatic, encrypted (AES-256) backups to multiple providers (iCloud, GitHub, IPFS, NAS) before cleaning.
- **AnalyticsEngine**: Collects real-time, on-device performance and cleaning metrics.

---

## 4. macOS Application Architecture (`Pinaklean.app`)

The macOS app provides a rich, visual, and interactive experience.

### UI/UX Layer: "Liquid Crystal" & "Sentient Interface"
- **Framework**: SwiftUI, leveraging modern features like `matchedGeometryEffect` for seamless morphing transitions.
- **Design System**: A "Liquid Crystal" aesthetic combining `NetraApp`'s glassmorphism (e.g., `FrostCard`) with `ChandraketuApp`'s functional visualizations.
- **Informative Motion**: All animations are physics-based (`interpolatingSpring`) and tied to `CoreHaptics` to provide tangible feedback. The UI is a single, cohesive entity that transforms to guide the user through the cleaning process.
- **Visualizations**:
  - **3D Sunburst Charts**: For interactive disk space visualization.
  - **Sankey Flow Diagrams**: To illustrate space recovery flow.
  - **Space-Time Explorer**: To visualize storage changes over time.

### Application Logic
- **Pattern**: Model-View-ViewModel (MVVM) with Swift Concurrency and Combine for reactive state management.
- **State Management**: A unified `UnifiedUIState` object manages the global UI state, driving the "Sentient Interface" transformations.
- **Integration**: The view models interact directly with the `PinakleanCore` engine for all business logic.

---

## 5. iOS Application Architecture (`Pinaklean iOS`)

The iOS app is a feat of engineering, designed to provide maximum utility within the strict limitations of the iOS sandbox.

### iOS Constraints & Solutions
- **Limitation**: Apps cannot access data outside their own sandbox.
- **Solution**: Pinaklean iOS focuses on:
  - Analyzing the app's own sandbox storage.
  - Intelligent duplicate detection within its own data and the user's photo library (with permission).
  - Providing smart storage recommendations and predictive forecasting.
  - Offering to clean its own cache and temporary files.

### Multi-Layer AI Architecture

#### Perception Layer (Data Understanding)
```swift
struct PerceptionAI {
    let visionAnalyzer: VisionAnalyzer // Image/video content analysis
    let nlpAnalyzer: NLPAnalyzer       // Document content analysis
    let behavioralAnalyzer: BehavioralAnalyzer // Usage pattern analysis
}
```

#### Cognition Layer (Decision Making)
```swift
struct CognitionAI {
    let multiObjectiveOptimizer: MultiObjectiveOptimizer
    let riskBenefitAnalyzer: RiskBenefitAnalyzer
    let reinforcementLearner: ReinforcementLearner
    let storageForecaster: StorageForecaster
}
```

#### Action Layer (Safe Execution)
```swift
struct ActionAI {
    let transactionManager: TransactionManager // Atomic, rollback-capable operations
    let safetySentinel: SafetySentinel         // Real-time safety monitoring
    let adaptiveInterface: AdaptiveInterface   // Emotional AI interface
}
```

### Advanced Features
- **Quantum-Inspired Optimization**: Uses quantum annealing and walk algorithms for complex optimization problems.
- **Neural Architecture Search (NAS)**: Self-evolving AI models that adapt to the user's data.
- **Emotional AI Interface**: The UI adapts based on detected user frustration or satisfaction.

### Performance & Optimization
- **Targets**: Aims for truly "invisible" performance with `<0.1%` active CPU usage and `<25MB` active memory usage.
- **Hardware Acceleration**: Deep integration with **Metal** and the **Apple Neural Engine (ANE)** for GPU-accelerated AI processing.
- **Energy-Aware Intelligence**: Operations are scheduled based on battery state and thermal conditions to minimize battery drain.

---

## 6. Security Architecture (Unified)

Pinaklean's security model is its most critical feature, designed to be uncompromising across both macOS and iOS.

### Zero-Trust Architecture
No operation is implicitly trusted. Every action is independently verified against a set of rules.
```swift
struct ZeroTrustSecurity {
    let continuousVerifier: ContinuousVerifier
    let privilegeEnforcer: PrivilegeEnforcer
    let microSegmenter: MicroSegmenter
    let anomalyDetector: AnomalyDetector
}
```

### Post-Quantum Security
To ensure future-proof data protection, Pinaklean plans to implement quantum-resistant cryptographic algorithms.
```swift
struct PostQuantumSecurity {
    let latticeCrypto: LatticeBasedCrypto
    let multivariateCrypto: MultivariateCrypto
    let hashSignatures: HashBasedSignatures
    let homomorphicEngine: HomomorphicEngine // For processing encrypted data
}
```

### Institutional Safety System
This is a multi-layered defense system ensuring perfect operational safety.
```swift
struct InstitutionalSafety {
    let fileSystemSafety: FileSystemSafety       // Protects critical files
    let operationalSafety: OperationalSafety     // Ensures safe execution with rollback
    let intelligenceSafety: IntelligenceSafety   // Validates AI decisions
    let autonomousSafety: AutonomousSafety       // Self-monitors for safety
}
```

---

## 7. Data & Persistence Architecture

A hybrid storage strategy is used to balance performance, persistence, and synchronization needs.

```swift
class DataManager {
    // Fast in-memory cache for session data
    private let cache = NSCache<NSString, CleanableItem>()
    
    // SQLite for the persistent file index (via GRDB)
    private let database: DatabaseQueue
    
    // Core Data for storing complex object graphs (e.g., user models)
    private let coreDataStack: CoreDataStack
    
    // CloudKit for syncing settings and metadata across devices
    private let cloudContainer: CKContainer
}
```

### Configuration & Secrets
- **User Preferences**: Stored in `UserDefaults`.
- **Sensitive Information**: Credentials for backup providers are securely stored in the **macOS Keychain**.

---

## 8. CLI Architecture (`pinaklean-cli`)

The CLI provides powerful, scriptable access to the core engine for developers.

### Framework
- Built using **Swift Argument Parser** for robust command, option, and argument parsing.

### Functionality
- Exposes all major `PinakleanCore` functions: `scan`, `clean`, `backup`, `config`.
- Supports multiple modes:
  - **Interactive Mode**: A Text-based UI (TUI) for guided cleaning.
  - **Direct Commands**: For scripting and automation (e.g., `pinaklean-cli clean --categories caches,logs`).
  - **Dry Run**: Preview changes without making any modifications (`--dry-run`).

### Integration
- The CLI is a lightweight wrapper that directly calls the `PinakleanCore` framework, ensuring 100% consistency with the GUI app's logic and safety.

---

## 9. CI/CD & DevOps Architecture

The project is supported by a comprehensive, production-grade CI/CD pipeline designed for reliability and security.

### Key Workflows
- **`swift-ci.yml`**: The core build and test workflow. It handles:
  - Building the project for macOS.
  - Running the full suite of unit and integration tests.
  - Generating code coverage reports.
  - Enforcing code style with SwiftLint.
- **`codeql-security.yml`**: Performs deep static analysis for security vulnerabilities using GitHub's CodeQL engine.
- **`security-scan.yml`**: A multi-faceted security workflow that includes:
  - **Secret Scanning** with `gitleaks`.
  - **Dependency Analysis** to check for vulnerabilities in third-party packages.
  - **Guardrail and Audit Tests** to ensure safety mechanisms are active.
- **`sbom.yml` & `license-check.yml`**: These workflows generate a Software Bill of Materials (SBOM) and verify license compliance, ensuring the project meets enterprise standards.

### Principles
- **All Green Policy**: All checks must pass before a pull request can be merged into `main`.
- **Automation**: The entire process, from testing to release, is fully automated to minimize human error.
- **Transparency**: All workflow statuses are publicly visible, providing a clear picture of the project's health.