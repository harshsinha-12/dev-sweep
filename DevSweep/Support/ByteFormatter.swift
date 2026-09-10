import Foundation

enum ByteFormatter {
    static func string(from bytes: Int64) -> String {
        if bytes <= 0 { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}

enum RelativeDateFormatter {
    static func string(from date: Date?) -> String {
        guard let date else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
