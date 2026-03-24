import SwiftUI

/// Mini line chart showing usage trend over time.
/// Only renders when there are enough data points spread over time to show a meaningful trend.
struct SparklineView: View {
    let snapshots: [UsageSnapshot]
    let label: String
    let keyPath: KeyPath<UsageSnapshot, Double>

    private var points: [Double] {
        snapshots.map { $0[keyPath: keyPath] }
    }

    /// Require 5+ points spanning at least 30 minutes
    private var hasMeaningfulData: Bool {
        guard points.count >= 5 else { return false }
        guard let first = snapshots.first, let last = snapshots.last else { return false }
        let span = last.timestamp.timeIntervalSince(first.timestamp)
        return span >= 1800  // 30 minutes
    }

    private var trendDelta: Double {
        guard points.count >= 2 else { return 0 }
        return (points.last ?? 0) - (points.first ?? 0)
    }

    private var trendIcon: String {
        switch trendDelta {
        case 3...:     return "arrow.up.right"
        case (-3)...:  return "arrow.right"
        default:       return "arrow.down.right"
        }
    }

    private var trendColor: Color {
        switch trendDelta {
        case 5...:     return .red       // rising fast = burning quota
        case 1...:     return .yellow    // rising slowly
        default:       return .green     // flat or dropping = recovering
        }
    }

    var body: some View {
        if hasMeaningfulData {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: trendIcon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(trendColor)
                    Text(String(format: "%+.0f%%", trendDelta))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(trendColor)
                }
                GeometryReader { geo in
                    sparklinePath(in: geo.size)
                        .stroke(
                            gradient,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )
                    sparklineArea(in: geo.size)
                        .fill(gradient.opacity(0.15))
                }
                .frame(height: 28)
            }
        }
    }

    private var gradient: LinearGradient {
        let color = trendColor
        return LinearGradient(
            colors: [color.opacity(0.6), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func sparklinePath(in size: CGSize) -> Path {
        guard points.count >= 2 else { return Path() }
        let maxVal = 100.0
        let step = size.width / CGFloat(points.count - 1)

        return Path { path in
            for (i, val) in points.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height * (1 - CGFloat(val / maxVal))
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
    }

    private func sparklineArea(in size: CGSize) -> Path {
        guard points.count >= 2 else { return Path() }
        let maxVal = 100.0
        let step = size.width / CGFloat(points.count - 1)

        return Path { path in
            path.move(to: CGPoint(x: 0, y: size.height))
            for (i, val) in points.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height * (1 - CGFloat(val / maxVal))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: CGFloat(points.count - 1) * step, y: size.height))
            path.closeSubpath()
        }
    }
}
