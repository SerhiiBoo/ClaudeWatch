import Foundation

@MainActor
protocol HookIngestionServiceProtocol: AnyObject {
    func ingest(url: URL)
}
