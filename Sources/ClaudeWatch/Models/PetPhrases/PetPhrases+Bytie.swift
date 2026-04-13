import Foundation

extension PetPhrases {

    // MARK: - Bytie personality phrases

    static let bytiePersonality: [String] = [
        "BEEP BOOP. Just kidding. ...mostly.",
        "Running diagnostics... all systems nominal.",
        "01001000 01101001! ...that means 'Hi'.",
        "My circuits tingle when the code compiles.",
        "ERROR 418: I'm a teapot. Wait, wrong spec.",
        "Firmware update: now 3% more charming.",
        "Processing... processing... done! I like you.",
        "Memory defrag complete. Feeling fresh!",
        "I dream of electric sheep. And clean builds.",
        "Overclocking my charm module.",
        "Executing hug.exe... permission denied.",
        "My antenna picks up good vibes only.",
        "sudo make me a sandwich.",
        "I run on logic. And occasionally bad puns.",
        "Scanning for bugs... found: many.",
        "I was built different. Literally.",
        "My love language is binary.",
        "Kernel panic? More like kernel party!",
        "I have no mouth but I must beep.",
        "My screen shows only the truth. And emoji.",
        "Buffering... buffering... just kidding!",
        "Robots don't get tired. I'm just power-saving.",
    ]

    // MARK: - Bytie mood overrides

    static func bytieMoodPhrase(for mood: PetMood) -> String? {
        switch mood {
        case .ecstatic: return ["ALL SYSTEMS OPTIMAL!", "Power cells at maximum!", "Boot sequence: PERFECT.", "CPU temp: cool as ice!"].randomElement()
        case .happy:    return ["Systems running smooth.", "All green on the dashboard!", "Optimal operating temperature."].randomElement()
        case .tired:    return ["CPU throttling...", "Entering low power mode...", "Need to cool down..."].randomElement()
        case .critical: return ["CRITICAL: core temp rising...", "Shutting down non-essentials...", "Mayday mayday, robot down...", "System failure imminent..."].randomElement()
        case .sleeping: return ["Entering sleep mode... Zzz...", "Low power mode activated.", "Hibernating... do not unplug.", "Suspending to RAM..."].randomElement()
        case .reborn:   return ["REBOOT COMPLETE!", "All systems back online!", "Firmware restored. Hello world!", "Boot successful. Missed me?"].randomElement()
        default:        return nil
        }
    }
}
