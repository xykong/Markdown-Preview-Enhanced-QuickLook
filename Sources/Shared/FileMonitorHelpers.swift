import Foundation

/// Pure-logic helpers for file change detection.
/// Extracted here so they are testable without UI dependencies.
enum FileMonitorHelpers {

    /// Returns `true` if the file metadata indicates the content has changed.
    static func shouldReload(
        newSize: UInt64, newMtime: Date?,
        knownSize: UInt64, knownMtime: Date?
    ) -> Bool {
        newSize != knownSize || newMtime != knownMtime
    }
}
