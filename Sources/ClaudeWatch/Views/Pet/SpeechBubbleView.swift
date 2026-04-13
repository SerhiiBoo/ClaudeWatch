import SwiftUI

// MARK: - Speech bubble

struct SpeechBubbleView: View {
    let text: String
    var compact: Bool = false
    /// Which edge the triangle pointer appears on.
    var pointerEdge: PointerEdge = .bottom

    enum PointerEdge {
        case top     // pointer at top → speech bubble is BELOW the pet
        case bottom  // pointer at bottom → speech bubble is ABOVE the pet
    }

    var body: some View {
        VStack(spacing: 0) {
            if pointerEdge == .top {
                trianglePointer(flipped: true)
            }

            Text(text)
                .font(.system(size: compact ? 10 : 12, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, compact ? 8 : 10)
                .padding(.vertical, compact ? 5 : 7)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
                }

            if pointerEdge == .bottom {
                trianglePointer(flipped: false)
            }
        }
        .frame(maxWidth: compact ? 200 : 260)
    }

    private func trianglePointer(flipped: Bool) -> some View {
        Triangle()
            .fill(.ultraThinMaterial)
            .frame(width: 8, height: 4)
            .rotationEffect(flipped ? .degrees(180) : .zero)
    }
}

// MARK: - Triangle shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
