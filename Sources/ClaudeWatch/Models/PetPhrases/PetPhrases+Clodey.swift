import Foundation

extension PetPhrases {

    // MARK: - Clodey personality phrases

    static let clodeyPersonality: [String] = [
        "I'm just a blob with dreams.",
        "Blobbing along happily!",
        "I may be round, but I'm well-rounded.",
        "Squish! ...that's just how I walk.",
        "My body is 100% vibes, 0% bones.",
        "Being amorphous has its perks!",
        "I'm not melting, this is just my shape.",
        "Blob life chose me.",
        "I wobble, therefore I am.",
        "Catch me doing a little squish!",
        "No sharp edges here. Only good vibes.",
        "I'm basically a hug with eyes.",
        "Blobbing is a valid life strategy.",
        "I don't have a skeleton. I have freedom.",
        "Round is a shape. A great shape.",
        "They see me blobbin'. They lovin'.",
        "Squishy on the outside, code on the inside.",
        "I contain multitudes. And also jelly.",
    ]

    // MARK: - Clodey mood overrides

    static func clodeyMoodPhrase(for mood: PetMood) -> String? {
        switch mood {
        case .ecstatic: return ["Maximum squish energy!", "I'm SO round with power!", "Blob at peak performance!"].randomElement()
        case .tired:    return ["Blobbing... slowly...", "Even blobs need rest...", "Squishing... with difficulty..."].randomElement()
        case .critical: return ["I'm... deflating...", "Blob down... blob down...", "Tell the other blobs... I tried..."].randomElement()
        case .reborn:   return ["FULL SQUISH RESTORED!", "Re-blobulated!", "The blob is back, baby!"].randomElement()
        default:        return nil
        }
    }
}
