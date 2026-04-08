import SwiftUI

struct ExtraUsageSectionView: View {
    let data: ExtraUsageData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            spendRow
            limitRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Extra usage")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if data.isEnabled {
                Label("On", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Label("Off", systemImage: "minus.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var spendRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "$%.2f spent", data.spentDollars))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%% used", data.utilization))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.06))
                        .overlay {
                            Capsule()
                                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                        }
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            .linearGradient(
                                colors: [barColor.opacity(0.9), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(data.utilization > 0 ? 8 : 0,
                                       geo.size.width * (data.utilization / 100)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }

    private var limitRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(String(format: "$%.2f", data.monthlyLimitDollars))
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Monthly spend limit")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    private var barColor: Color {
        switch data.utilization {
        case ..<40:  return .green
        case 40..<80: return .yellow
        default:      return .red
        }
    }
}
