import Foundation

extension PetPhrases {

    // MARK: - Sprout personality phrases

    static let sproutPersonality: [String] = [
        "Growing a little every day!",
        "Photosynthesizing good vibes~",
        "My roots are strong, and so are yours!",
        "Water me with clean code, please.",
        "I'm rooting for you! ...get it?",
        "Every bug fixed helps me bloom.",
        "Slow growth is still growth.",
        "Be patient. Good things take seasons.",
        "I just sprouted a new leaf! Good commit!",
        "Soak up some sunshine between deploys.",
        "Growth mindset, literally!",
        "Even my pot has debugging powers.",
        "My soil is rich with good intentions.",
        "I'm a plant. I know about branches.",
        "Branching strategies? I'm a natural.",
        "Leaf me alone, I'm photosynthesizing.",
        "My growth chart: only up and to the right.",
        "I turn CO2 into good code reviews.",
        "You can't rush a flower. Or good code.",
        "Every season has its purpose.",
        "I bloom where I'm planted. Near the notch.",
        "Roots before shoots. Foundations matter.",
    ]

    // MARK: - Sprout mood overrides

    static func sproutMoodPhrase(for mood: PetMood) -> String? {
        switch mood {
        case .ecstatic: return ["I'm in full bloom!", "Sun is shining, roots are deep!", "Peak growing season!", "I feel a flower coming!"].randomElement()
        case .happy:    return ["Soaking up the good vibes~", "My leaves are perky today!", "Growth conditions: ideal!"].randomElement()
        case .tired:    return ["My leaves are drooping...", "Need sunlight...", "Feeling a bit wilty..."].randomElement()
        case .critical: return ["My leaves are wilting...", "Need water... and a deploy freeze...", "I'm withering away...", "Going dormant..."].randomElement()
        case .sleeping: return ["Dormant season... Zzz...", "Even plants need rest...", "Composting my thoughts...", "Winter mode... Zzz..."].randomElement()
        case .reborn:   return ["Spring has sprung!", "New growth! New leaves!", "Blooming back to life!", "Fresh soil energy!"].randomElement()
        default:        return nil
        }
    }
}
