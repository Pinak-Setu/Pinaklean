import Foundation

/// Calculates deltas and produces incremental backup snapshots
public struct IncrementalBackupManager {
    public init() {}

    public func diff(previous: [BackupFileChange], current: [BackupFileChange]) -> [BackupFileChange] {
        // Placeholder: in real implementation, compute actual diffs
        return current
    }

    public func createIncrementalBackup(changes: [BackupFileChange]) throws -> DiskSnapshot {
        return DiskSnapshot.incremental(changes: changes)
    }
}

