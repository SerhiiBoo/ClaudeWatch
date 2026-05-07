import Foundation

@MainActor
final class NotificationCardViewModel: ObservableObject, Identifiable {
    let item: NotificationCardItem
    nonisolated var id: UUID { item.id }

    @Published private(set) var elapsed: TimeInterval = 0
    var progress: Double { min(elapsed / item.timeout, 1) }

    private var timer: Timer?
    private var isPaused = false

    init(item: NotificationCardItem) {
        self.item = item
    }

    func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func pause()  { isPaused = true }
    func resume() { isPaused = false }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !isPaused else { return }
        elapsed += 1.0 / 30.0
    }

    deinit { timer?.invalidate() }
}
