import SwiftUI

/// A self-contained card rendered to an NSImage for sharing via the system share sheet.
/// Uses explicit dark colors — NSColor.windowBackgroundColor ignores colorScheme inside ImageRenderer.
struct GameResultSnapshotView: View {
    let score: Int
    let highScore: Int
    let isNewHighScore: Bool
    let elapsedSeconds: Double
    let difficulty: Double
    let variant: PetVariant

    private static let background = Color(red: 0.04, green: 0.04, blue: 0.12)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.15))
            petSection
            Divider().overlay(.white.opacity(0.15))
            scoreSection
            Divider().overlay(.white.opacity(0.15))
            statsRow
            Divider().overlay(.white.opacity(0.15))
            footerRow
        }
        .frame(width: 320)
        .background(Self.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .padding(14)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.purple)
            Text("TOKEN RUSH")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            Spacer()
            Text(Date(), style: .time)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Pet showcase

    private var petSection: some View {
        AnimatedSpriteView(
            animation: .idle,
            pixelSize: 5.0,
            character: variant.character,
            variant: variant
        )
        .padding(.vertical, 16)
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 6) {
            Text("Score: \(score)")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(.white)

            if isNewHighScore {
                Text("NEW HIGH SCORE!")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.yellow)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 14)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack {
            statItem(icon: "clock.fill", label: "Time", value: formattedTime)
            Divider()
                .frame(height: 28)
                .overlay(.white.opacity(0.15))
            statItem(icon: "speedometer", label: "Difficulty", value: String(format: "%.1f×", difficulty))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Text("Claude Watch")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let total = Int(elapsedSeconds)
        if total < 60 {
            return "\(total)s"
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
