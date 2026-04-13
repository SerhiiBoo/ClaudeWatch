import SwiftUI

extension PopoverView {

    // MARK: - Plan + Streak row

    func planRow(usage: UsageData) -> some View {
        let streak = UsageHistoryService.currentStreak()

        return HStack(alignment: .center, spacing: 8) {
            Text("PLAN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            Spacer()

            if streak > 0 {
                HStack(spacing: 3) {
                    // Flame glyphs representing each day of streak (up to 7)
                    let shown = min(streak, 7)
                    ForEach(0..<shown, id: \.self) { i in
                        Image(systemName: "flame.fill")
                            .font(.system(size: streak >= 7 ? 10 : 8))
                            .foregroundStyle(
                                i == shown - 1
                                    ? (streak >= 7 ? .orange : .primary.opacity(0.6))
                                    : .primary.opacity(0.15)
                            )
                    }
                    if streak > 7 {
                        Text("+\(streak - 7)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.orange.opacity(0.8))
                    }
                }
                .help("\(streak)-day streak")
            }

            Text(usage.plan)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
