import SwiftUI

// MARK: - Overlay SwiftUI view

/// Root SwiftUI view for the notch overlay window.
/// Pet at the TOP (touching menu bar), speech bubble extends below.
struct NotchPetOverlayView: View {
    @ObservedObject var petService: NotchPetService

    private var petSize: PetSize { AppSettings.petSize }

    var body: some View {
        VStack(spacing: 2) {
            // Pet at top — hangs from menu bar edge
            AnimatedSpriteView(
                animation: petService.animation,
                pixelSize: petSize.pixelSize,
                character: petService.character,
                variant: petService.variant
            )
            .onTapGesture { petService.poke() }
            .help("Click to poke \(petService.character.displayName)!")

            // Speech bubble below the pet
            if petService.showSpeechBubble, let phrase = petService.currentPhrase {
                SpeechBubbleView(text: phrase, compact: true, pointerEdge: .top)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5, anchor: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: petService.showSpeechBubble)
    }
}
