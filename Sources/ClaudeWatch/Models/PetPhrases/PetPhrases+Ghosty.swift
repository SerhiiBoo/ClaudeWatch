import Foundation

extension PetPhrases {

    // MARK: - Ghosty personality phrases

    static let ghostyPersonality: [String] = [
        "Boo! ...did I scare you?",
        "I can phase through bugs. You can too!",
        "Being transparent is my whole thing.",
        "I'm not haunting, I'm helping!",
        "*phases through your monitor* Nice code!",
        "Spooky fact: most bugs are already dead code.",
        "I float, therefore I am.",
        "The real ghost is the code from 3am.",
        "Ooooo~ ...that's my thinking sound.",
        "I've seen things in the codebase... spooky.",
        "I'm incorporeal but my advice is solid.",
        "Ghosting is only okay when I do it.",
        "I haunt in a supportive way.",
        "The scariest thing? Untyped JavaScript.",
        "My sheet is designer. Very chic.",
        "I go through walls. And code reviews.",
        "Boo-lean logic is my specialty.",
        "I'm dead serious about clean code.",
        "Spirits are high! Get it? I'm a spirit!",
        "I vanish sometimes. It's not personal.",
        "The afterlife has great WiFi, actually.",
        "I've been coding since... the afterlife.",
        "Don't be scared. I only bite bugs.",
    ]

    // MARK: - Ghosty mood overrides

    static func ghostyMoodPhrase(for mood: PetMood) -> String? {
        switch mood {
        case .ecstatic: return ["I could haunt TWO houses right now!", "Ethereal energy at max!", "Feeling supernaturally good!", "BOO-TIFUL day!"].randomElement()
        case .happy:    return ["Floating happily~", "My aura is glowing!", "Hauntingly good vibes!"].randomElement()
        case .tired:    return ["Even ghosts get tired...", "My glow is dimming...", "Less spooky, more sleepy..."].randomElement()
        case .critical: return ["I'm fading... even for a ghost...", "Becoming too transparent...", "The afterlife's afterlife awaits...", "I can see through myself..."].randomElement()
        case .sleeping: return ["Haunting hours are over... Zzz...", "Even ghosts need beauty sleep...", "Floating in dreamland...", "Ghost nap. Very quiet."].randomElement()
        case .reborn:   return ["I'm BAAACK! Miss me?", "Re-materialized!", "You can't keep a good ghost down!", "Respawned!"].randomElement()
        default:        return nil
        }
    }
}
