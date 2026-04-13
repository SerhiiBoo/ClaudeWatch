import SwiftUI

// MARK: - Pet view for the popover

struct NotchPetView: View {
    @ObservedObject var petService: NotchPetService
    var pixelSize: CGFloat = 1.5

    var body: some View {
        AnimatedSpriteView(
            animation: petService.animation,
            pixelSize: pixelSize,
            character: petService.character,
            variant: petService.variant
        )
        .onTapGesture { petService.poke() }
        .help("Click to poke \(petService.character.displayName)!")
        .animation(.easeInOut(duration: 0.3), value: petService.animation)
    }
}

// MARK: - Mini pet for the popover header

struct MiniPetView: View {
    @ObservedObject var petService: NotchPetService

    var body: some View {
        NotchPetView(
            petService: petService,
            pixelSize: 1.5
        )
    }
}
