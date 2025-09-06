import Foundation
import os.log
import Combine

/// Performance monitoring and SLO tracking for Pinaklean Engine
/// Implements Ironclad DevOps v2.1 performance budgets and observability
public actor PerformanceMonitor: ObservableObject {
    
    // MARK: - Performance Budgets (Ironclad v2.1)
    public struct PerformanceBudgets {
        public static let webLCP: TimeInterval = 2.5 // seconds
        public static let webCLS: Double = 0.1 // p75 mid-tier
        public static let apiP95: TimeInterval = 0.3 // 300ms
        public static let mobileFPS: Double = 60.0 // fps
        public static let mobileJank: Double = 1.0 // <1%
    }
    
    // MARK: - Metrics Collection
    @Published public var currentMetrics = PerformanceMetrics()
    @Published public var sloStatus = SLOStatus()
    
    private let logger = Logger(subsystem: "com.pinaklean", category: "PerformanceMonitor")
    private var metricsHistory: [PerformanceMetrics] = []
    private let maxHistorySize = 1000
    
    // MARK: - SLO Definitions
    public struct SLO {
        let name: String
        let target: Double
        let measurement: String
        let window: TimeInterval
        
        public static let scanLatency = SLO(
            name: "scan_latency_p95",
            target: PerformanceBudgets.apiP95,
            measurement: "p95_latency_ms",
            window: 300 // 5 minutes
        )
        
        public static let cleanLatency = SLO(
            name: "clean_latency_p95", 
            target: PerformanceBudgets.apiP95,
            measurement: "p95_latency_ms",
            window: 300
        )
        
        public static let errorRate = SLO(
            name: "error_rate",
            target: 0.001, // 0.1%
            measurement: "error_percentage",
            window: 300
        )
        
        public static let availability = SLO(
            name: "availability",
            target: 0.999, // 99.9%
            measurement: "uptime_percentage", 
            window: 86400 // 24 hours
        )
    }
    
    // MARK: - Performance Metrics
    public struct PerformanceMetrics: Codable {
        public var scanLatency: TimeInterval = 0
        public var cleanLatency: TimeInterval = 0
        public var memoryUsage: UInt64 = 0
        public var cpuUsage: Double = 0
        public var errorCount: Int = 0
        public var successCount: Int = 0
        public var timestamp: Date = Date()
        
        public var errorRate: Double {
            let total = errorCount + successCount
            return total > 0 ? Double(errorCount) / Double(total) : 0
        }
        
        public var availability: Double {
            let total = errorCount + successCount
            return total > 0 ? Double(successCount) / Double(total) : 1.0
        }
    }
    
    // MARK: - SLO Status
    public struct SLOStatus: Codable {
        public var scanLatencyStatus: SLOStatusItem = SLOStatusItem()
        public var cleanLatencyStatus: SLOStatusItem = SLOStatusItem()
        public var errorRateStatus: SLOStatusItem = SLOStatusItem()
        public var availabilityStatus: SLOStatusItem = SLOStatusItem()
        public var lastUpdated: Date = Date()
        
        public var overallStatus: String {
            let statuses = [scanLatencyStatus, cleanLatencyStatus, errorRateStatus, availabilityStatus]
            let failing = statuses.filter { !$0.isHealthy }
            return failing.isEmpty ? "healthy" : "degraded"
        }
    }
    
    public struct SLOStatusItem: Codable {
        public var isHealthy: Bool = true
        public var currentValue: Double = 0
        public var targetValue: Double = 0
        public var errorBudget: Double = 1.0
        public var lastViolation: Date?
    }
    
    // MARK: - Initialization
    public init() {
        logger.info("PerformanceMonitor initialized with Ironclad v2.1 budgets")
    }
    
    // MARK: - Metrics Recording
    public func recordScanLatency(_ latency: TimeInterval) {
        currentMetrics.scanLatency = latency
        currentMetrics.timestamp = Date()
        
        // Check SLO compliance
        let isHealthy = latency <= PerformanceBudgets.apiP95
        sloStatus.scanLatencyStatus.isHealthy = isHealthy
        sloStatus.scanLatencyStatus.currentValue = latency * 1000 // Convert to ms
        sloStatus.scanLatencyStatus.targetValue = PerformanceBudgets.apiP95 * 1000
        
        if !isHealthy {
            sloStatus.scanLatencyStatus.lastViolation = Date()
            logger.warning("Scan latency SLO violation: \(latency)s > \(PerformanceBudgets.apiP95)s")
        }
        
        addToHistory(currentMetrics)
    }
    
    public func recordCleanLatency(_ latency: TimeInterval) {
        currentMetrics.cleanLatency = latency
        currentMetrics.timestamp = Date()
        
        // Check SLO compliance
        let isHealthy = latency <= PerformanceBudgets.apiP95
        sloStatus.cleanLatencyStatus.isHealthy = isHealthy
        sloStatus.cleanLatencyStatus.currentValue = latency * 1000 // Convert to ms
        sloStatus.cleanLatencyStatus.targetValue = PerformanceBudgets.apiP95 * 1000
        
        if !isHealthy {
            sloStatus.cleanLatencyStatus.lastViolation = Date()
            logger.warning("Clean latency SLO violation: \(latency)s > \(PerformanceBudgets.apiP95)s")
        }
        
        addToHistory(currentMetrics)
    }
    
    public func recordMemoryUsage(_ usage: UInt64) {
        currentMetrics.memoryUsage = usage
        currentMetrics.timestamp = Date()
        
        // Memory budget: 1GB max
        let memoryBudget: UInt64 = 1_000_000_000 // 1GB
        if usage > memoryBudget {
            logger.warning("Memory usage exceeds budget: \(usage) > \(memoryBudget)")
        }
        
        addToHistory(currentMetrics)
    }
    
    public func recordError() {
        currentMetrics.errorCount += 1
        currentMetrics.timestamp = Date()
        
        // Update error rate SLO
        let errorRate = currentMetrics.errorRate
        sloStatus.errorRateStatus.isHealthy = errorRate <= SLO.errorRate.target
        sloStatus.errorRateStatus.currentValue = errorRate * 100 // Convert to percentage
        sloStatus.errorRateStatus.targetValue = SLO.errorRate.target * 100
        
        if !sloStatus.errorRateStatus.isHealthy {
            sloStatus.errorRateStatus.lastViolation = Date()
            logger.warning("Error rate SLO violation: \(errorRate * 100)% > \(SLO.errorRate.target * 100)%")
        }
        
        addToHistory(currentMetrics)
    }
    
    public func recordSuccess() {
        currentMetrics.successCount += 1
        currentMetrics.timestamp = Date()
        
        // Update availability SLO
        let availability = currentMetrics.availability
        sloStatus.availabilityStatus.isHealthy = availability >= SLO.availability.target
        sloStatus.availabilityStatus.currentValue = availability * 100 // Convert to percentage
        sloStatus.availabilityStatus.targetValue = SLO.availability.target * 100
        
        if !sloStatus.availabilityStatus.isHealthy {
            sloStatus.availabilityStatus.lastViolation = Date()
            logger.warning("Availability SLO violation: \(availability * 100)% < \(SLO.availability.target * 100)%")
        }
        
        addToHistory(currentMetrics)
    }
    
    // MARK: - Health Check Endpoint
    public func healthCheck() -> HealthCheckResult {
        let overallStatus = sloStatus.overallStatus
        let isHealthy = overallStatus == "healthy"
        
        return HealthCheckResult(
            status: isHealthy ? "healthy" : "degraded",
            timestamp: Date(),
            metrics: currentMetrics,
            sloStatus: sloStatus,
            uptime: getUptime(),
            version: getVersion()
        )
    }
    
    // MARK: - Performance Analysis
    public func getPerformanceReport() -> PerformanceReport {
        let recentMetrics = getRecentMetrics(window: 300) // Last 5 minutes
        
        return PerformanceReport(
            averageScanLatency: calculateAverage(metrics: recentMetrics, keyPath: \.scanLatency),
            averageCleanLatency: calculateAverage(metrics: recentMetrics, keyPath: \.cleanLatency),
            p95ScanLatency: calculatePercentile(metrics: recentMetrics, keyPath: \.scanLatency, percentile: 95),
            p95CleanLatency: calculatePercentile(metrics: recentMetrics, keyPath: \.cleanLatency, percentile: 95),
            averageMemoryUsage: calculateAverage(metrics: recentMetrics, keyPath: \.memoryUsage),
            errorRate: currentMetrics.errorRate,
            availability: currentMetrics.availability,
            sloCompliance: getSLOCompliance(),
            recommendations: generateRecommendations()
        )
    }
    
    // MARK: - Private Methods
    private func addToHistory(_ metrics: PerformanceMetrics) {
        metricsHistory.append(metrics)
        
        // Keep only recent history
        if metricsHistory.count > maxHistorySize {
            metricsHistory.removeFirst(metricsHistory.count - maxHistorySize)
        }
    }
    
    private func getRecentMetrics(window: TimeInterval) -> [PerformanceMetrics] {
        let cutoff = Date().addingTimeInterval(-window)
        return metricsHistory.filter { $0.timestamp >= cutoff }
    }
    
    private func calculateAverage(metrics: [PerformanceMetrics], keyPath: KeyPath<PerformanceMetrics, TimeInterval>) -> TimeInterval {
        guard !metrics.isEmpty else { return 0 }
        let sum = metrics.reduce(0) { $0 + $1[keyPath: keyPath] }
        return sum / Double(metrics.count)
    }
    
    private func calculateAverage(metrics: [PerformanceMetrics], keyPath: KeyPath<PerformanceMetrics, UInt64>) -> UInt64 {
        guard !metrics.isEmpty else { return 0 }
        let sum = metrics.reduce(0) { $0 + $1[keyPath: keyPath] }
        return sum / UInt64(metrics.count)
    }
    
    private func calculatePercentile(metrics: [PerformanceMetrics], keyPath: KeyPath<PerformanceMetrics, TimeInterval>, percentile: Int) -> TimeInterval {
        guard !metrics.isEmpty else { return 0 }
        let values = metrics.map { $0[keyPath: keyPath] }.sorted()
        let index = Int(Double(values.count) * Double(percentile) / 100.0)
        return values[min(index, values.count - 1)]
    }
    
    private func getSLOCompliance() -> [String: Bool] {
        return [
            "scan_latency": sloStatus.scanLatencyStatus.isHealthy,
            "clean_latency": sloStatus.cleanLatencyStatus.isHealthy,
            "error_rate": sloStatus.errorRateStatus.isHealthy,
            "availability": sloStatus.availabilityStatus.isHealthy
        ]
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if !sloStatus.scanLatencyStatus.isHealthy {
            recommendations.append("Consider optimizing file scanning algorithm or reducing parallel workers")
        }
        
        if !sloStatus.cleanLatencyStatus.isHealthy {
            recommendations.append("Consider implementing batch deletion or async cleanup")
        }
        
        if !sloStatus.errorRateStatus.isHealthy {
            recommendations.append("Investigate error sources and implement better error handling")
        }
        
        if !sloStatus.availabilityStatus.isHealthy {
            recommendations.append("Check system resources and implement circuit breakers")
        }
        
        if currentMetrics.memoryUsage > 500_000_000 { // 500MB
            recommendations.append("Consider implementing memory cleanup or reducing cache size")
        }
        
        return recommendations
    }
    
    private func getUptime() -> TimeInterval {
        // Simplified uptime calculation
        return ProcessInfo.processInfo.systemUptime
    }
    
    private func getVersion() -> String {
        return "1.0.0" // Should be read from bundle
    }
}

// MARK: - Supporting Types
public struct HealthCheckResult: Codable {
    public let status: String
    public let timestamp: Date
    public let metrics: PerformanceMonitor.PerformanceMetrics
    public let sloStatus: PerformanceMonitor.SLOStatus
    public let uptime: TimeInterval
    public let version: String
}

public struct PerformanceReport: Codable {
    public let averageScanLatency: TimeInterval
    public let averageCleanLatency: TimeInterval
    public let p95ScanLatency: TimeInterval
    public let p95CleanLatency: TimeInterval
    public let averageMemoryUsage: UInt64
    public let errorRate: Double
    public let availability: Double
    public let sloCompliance: [String: Bool]
    public let recommendations: [String]
}