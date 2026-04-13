import SwiftUI

/// Identity key that triggers animation task restart when animation or variant changes.
struct AnimationTaskKey: Equatable {
    let animation: PetAnimation
    let variant: PetVariant
}

/// View modifier that cycles `frameIndex` through sprite frames at the correct speed.
/// Attach to any view that reads `frameIndex` to drive pixel art animation.
struct SpriteAnimator: ViewModifier {
    let animation: PetAnimation
    let variant: PetVariant
    @Binding var frameIndex: Int

    private var taskKey: AnimationTaskKey {
        AnimationTaskKey(animation: animation, variant: variant)
    }

    func body(content: Content) -> some View {
        content.task(id: taskKey) {
            frameIndex = 0
            let frames = CharacterSprites.frames(for: animation, variant: variant)
            guard frames.count > 1 else { return }
            let duration = CharacterSprites.frameDuration(for: animation, variant: variant)
            let nanoseconds = UInt64(duration * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard !Task.isCancelled else { break }
                frameIndex = (frameIndex + 1) % frames.count
            }
        }
    }
}

extension View {
    func spriteAnimation(animation: PetAnimation, variant: PetVariant, frameIndex: Binding<Int>) -> some View {
        modifier(SpriteAnimator(animation: animation, variant: variant, frameIndex: frameIndex))
    }
}
