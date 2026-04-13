import Foundation

protocol Logging {
    static func log(_ level: LogService.Level, category: String, _ message: String, details: [String: String])
    static func error(_ category: String, _ message: String, error: Error?, details: [String: String])
    static func warning(_ category: String, _ message: String, details: [String: String])
    static func info(_ category: String, _ message: String)
}
