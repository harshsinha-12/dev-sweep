import Foundation

enum ByteFormatter {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func string(from bytes: Int64) -> String {
        if bytes <= 0 { return "0 KB" }
        return formatter.string(fromByteCount: bytes)
    }
}

enum RelativeDateFormatter {
    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static func string(from date: Date?) -> String {
        guard let date else { return "Unknown" }
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
