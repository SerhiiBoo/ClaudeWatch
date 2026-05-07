import AppKit
import CoreGraphics
import Darwin
import Foundation

enum Reachability: Equatable {
    case reachable
    case hidden(reason: HiddenReason)

    enum HiddenReason: Equatable {
        case notFrontmost
        case notOnScreen
        case occluded
    }
}

final class TerminalReachabilityService {
    func reachability(pid: pid_t, bundleId: String) -> Reachability {
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              frontmost.bundleIdentifier == bundleId else {
            return .hidden(reason: .notFrontmost)
        }

        // pid is Claude's CLI PID — terminal windows are owned by the terminal app's own PID
        let terminalPID = frontmost.processIdentifier

        let opts = CGWindowListOption.optionOnScreenOnly
        let windowList = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] ?? []

        let targetIndexes = windowList.indices.filter { i in
            (windowList[i][kCGWindowOwnerPID as String] as? pid_t) == terminalPID
        }

        guard !targetIndexes.isEmpty else {
            return .hidden(reason: .notOnScreen)
        }

        for idx in targetIndexes {
            guard let bounds = boundsRect(from: windowList[idx]) else { continue }
            // Accumulate rects of all windows above this one in z-order
            var coverUnion = CGRect.null
            for above in windowList[0..<idx] {
                if let r = boundsRect(from: above) { coverUnion = coverUnion.union(r) }
            }
            // If this window isn't fully covered, the terminal is visible
            if !coverUnion.contains(bounds) { return .reachable }
        }

        return .hidden(reason: .occluded)
    }

    private func boundsRect(from info: [String: Any]) -> CGRect? {
        guard let dict = info[kCGWindowBounds as String] as? [String: Any],
              let rect = CGRect(dictionaryRepresentation: dict as CFDictionary) else { return nil }
        return rect
    }
}
