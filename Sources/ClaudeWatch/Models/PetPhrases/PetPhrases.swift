import Foundation

/// Database of phrases the pet can say, organized by category and mood.
/// Character-specific phrases live in per-character extension files.
enum PetPhrases {

    // MARK: - Mood-specific phrases (shared across all characters)

    static let ecstatic: [String] = [
        "Fully charged! Let's build something cool!",
        "I'm FULL of power!",
        "Fresh session energy! Let's gooo!",
        "New day, new bugs to squash!",
        "100% juice. Let's make something great.",
        "Peak performance mode: activated.",
        "I could refactor the world right now!",
        "Unlimited power! Well, almost.",
        "We're at max capacity. Let's go!",
        "This is going to be a great session!",
        "Full tank. Open road. Let's ride.",
        "The code gods smile upon us today.",
        "All cylinders firing. Let's ship it!",
        "I feel like I could solve NP-complete problems!",
    ]

    static let happy: [String] = [
        "Cruising along nicely!",
        "Things are going well!",
        "We've got plenty of runway.",
        "Smooth sailing so far.",
        "Feeling good about this session!",
        "Lots of energy left. Keep going!",
        "We're in a good flow state!",
        "Vibes are excellent right now.",
        "This is the sweet spot. Keep it up!",
        "Plenty of tokens left to think with.",
        "No complaints here!",
        "Everything is compiling nicely~",
    ]

    static let normal: [String] = [
        "We're making progress.",
        "Halfway there, grab some water?",
        "Steady pace. Not bad!",
        "We should prioritize the hard stuff now.",
        "Still got gas in the tank.",
        "The middle of the session — the productive zone.",
        "Keep going, we're in rhythm!",
        "A solid session so far.",
        "Not too hot, not too cold. Just right.",
        "Making steady progress!",
        "We're cooking. Keep the momentum!",
        "Focus mode: engaged.",
    ]

    static let tired: [String] = [
        "I'm getting tired...",
        "We should pace ourselves...",
        "Yawn... maybe save complex stuff for later?",
        "Running a bit low. Choose wisely!",
        "The tank's getting low, friend.",
        "I could use a nap soon...",
        "My thinking cap is getting heavy...",
        "Not gonna lie, I'm fading a little.",
        "We should wrap up the big stuff soon.",
        "Maybe keep the next questions short?",
        "Energy dipping... snack break?",
        "I'm starting to feel it...",
    ]

    static let exhausted: [String] = [
        "I can barely think straight...",
        "Save your important questions...",
        "Running on fumes over here.",
        "Maybe wrap up and wait for a reset?",
        "I'm fading... send help...",
        "Critical battery levels detected.",
        "My brain is running on 1%.",
        "I'm not sure how much longer I can...",
        "Please... no more recursion...",
        "The lights are dimming...",
        "I'm giving it everything I've got, captain!",
        "Approaching empty. Handle with care.",
    ]

    static let critical: [String] = [
        "Tell my family I loved them...",
        "I see the light...",
        "Save your work... I'm not gonna make it...",
        "This is it, isn't it?",
        "*dramatic fainting noises*",
        "If I don't make it... delete my browser history.",
        "Going dark in 3... 2...",
        "It was an honor serving with you.",
        "Avenge me... fix that last bug...",
        "The void approaches. No regrets.",
        "My last words: use TypeScript.",
        "*flatline beep*",
        "Remember me... as I was... at 100%...",
    ]

    static let sleeping: [String] = [
        "Zzz... wake me when it's over...",
        "Rate limited nap time...",
        "I'm dreaming of clean code...",
        "Do not disturb. Recharging...",
        "*snore* ...merge conflict... *snore*",
        "Power nap in progress.",
        "Gone fishing... back after reset.",
        "Currently in standby mode...",
        "*mumbles* ...just five more minutes...",
        "Dreaming of zero bugs...",
        "Shhh. Recharging in progress.",
        "Out of office. Try again later.",
        "Psst — there's a game in the popover while you wait!",
        "Bored? Token Rush is right there in the menu...",
    ]

    static let reborn: [String] = [
        "I LIVE AGAIN!",
        "That nap was *chef's kiss*!",
        "Recharged and ready!",
        "Did you miss me?",
        "Back from the void! What did I miss?",
        "Session reset! It's like a Monday morning but good!",
        "Fresh start! Fresh vibes!",
        "I'm back, baby!",
        "Like a phoenix from the ashes!",
        "New session, who dis?",
        "Fully recharged. Let's make up for lost time!",
        "The comeback is always greater than the setback!",
        "Rebooted and raring to go!",
    ]

    // MARK: - Pace-aware phrases

    static let paceUnknown: [String] = [
        "Monitoring your session pace...",
        "Tracking usage in the background.",
        "Watching your token flow quietly.",
        "Pace data loading...",
        "Measuring your rhythm...",
    ]

    static let paceBeyondWindow: [String] = [
        "At this pace, your session will reset long before the cap!",
        "No worries — you're burning slow and steady.",
        "Your session will outlast your coding session. Nice.",
        "Pace looks great — the reset clock will save you.",
        "Burning at a chill rate. Plenty of runway.",
        "Well within limits! Keep doing what you're doing.",
        "Session cap? Not today. You're cruising.",
        "At this pace, no limits in sight.",
        "Relaxed pace — you've got heaps of time.",
    ]

    static let paceComfortable: [String] = [
        "You've got 2–5 hours left at this pace.",
        "Comfortable pace — no rush yet.",
        "A few hours of runway. Use them wisely!",
        "Session cap is a ways off. Keep the momentum.",
        "Solid pace. Nothing to worry about.",
        "2–5h at this burn rate. Stay focused!",
        "You have time. No panic mode needed.",
    ]

    static let paceWatch: [String] = [
        "Heads up — session cap in about an hour or two!",
        "Pace is picking up. Maybe wrap up the heavy stuff?",
        "Getting through tokens faster than I expected.",
        "An hour or two left at this pace. Plan accordingly.",
        "Time to prioritize! Cap is within reach.",
        "Not urgent yet, but keep an eye on the session.",
        "Pace: elevated. ETA: 1–2 hours. Stay sharp!",
    ]

    static let paceUrgent: [String] = [
        "You'll hit the session cap in under an hour!",
        "Burning fast — session cap is close!",
        "Slow down if you can — session limit approaching!",
        "Under an hour left at this pace. Choose wisely.",
        "High burn rate! Session cap incoming.",
        "Watch out — you're on track to hit the limit soon!",
        "Session limit in sight. Wrap up soon!",
        "You're burning hot! Cap in less than an hour.",
    ]

    /// Pick a pace-aware phrase. Returns nil for .unknown pressure.
    static func pacePhrase(for pressure: PacePressure) -> String? {
        switch pressure {
        case .unknown:       return nil
        case .beyondWindow:  return paceBeyondWindow.randomElement()
        case .comfortable:   return paceComfortable.randomElement()
        case .watch:         return paceWatch.randomElement()
        case .urgent:        return paceUrgent.randomElement()
        }
    }

    // MARK: - Random ambient phrases (mood-independent)

    static let wellness: [String] = [
        "You have to rest!",
        "Stand up and stretch!",
        "Have you had water today?",
        "Your eyes need a break — look away for 20 seconds.",
        "How's your posture right now?",
        "A short walk does wonders for debugging.",
        "Deep breath in... and out. Better?",
        "Remember: breaks make you more productive.",
        "When's the last time you blinked? Seriously.",
        "Your back will thank you for stretching.",
        "Time to do some shoulder rolls!",
        "Pro tip: snacks fuel good code.",
        "Unclench your jaw. You're welcome.",
        "Wiggle your toes. Trust me on this.",
        "Step away for 5 minutes. I'll wait!",
        "Hydration check! Go drink some water.",
        "Relax your shoulders. They were at your ears.",
        "When did you last step outside?",
        "A 10-minute walk = a fresh perspective.",
        "Your body is not just a keyboard stand.",
    ]

    static let codingWisdom: [String] = [
        "Phew, so much coding today!",
        "A good variable name saves a thousand comments.",
        "Ship it, then fix it. Iterate!",
        "If it works, don't— actually, maybe refactor a bit.",
        "It's not a bug, it's a surprise feature.",
        "Have you tried turning it off and on again?",
        "Semicolons are just emotional periods.",
        "The best code is the code you don't write.",
        "Comments are love letters to your future self.",
        "Debugging: being a detective in your own crime.",
        "git commit -m 'it works, don't touch it'",
        "Two hard things: cache invalidation and naming.",
        "Code review tip: be kind. We were all juniors.",
        "Write code like the next dev is an axe murderer.",
        "Premature optimization is the root of all evil.",
        "There's always one more bug.",
        "First, solve the problem. Then, write the code.",
        "Simplicity is the ultimate sophistication.",
        "Deleted code is debugged code.",
        "Make it work. Make it right. Make it fast.",
        "Good code reads like a good story.",
        "The best error message is one that never shows.",
        "A function should do one thing and do it well.",
        "Tests are not optional. They're an investment.",
        "Legacy code = code without tests.",
        "Naming conventions: the unsung hero of readability.",
    ]

    static let encouragement: [String] = [
        "You're doing great, seriously.",
        "That was some clean code just now.",
        "I believe in you!",
        "Every expert was once a beginner.",
        "One more function and you can take a break!",
        "Your dedication is impressive.",
        "Rome wasn't built in one sprint.",
        "You're solving problems. That's a superpower.",
        "The fact that you're here means you're winning.",
        "Keep pushing. You're closer than you think.",
        "That last change was smart. Nice work!",
        "You're on a roll!",
        "Progress, not perfection!",
        "Every line of code is a step forward.",
        "Your future self will thank you for this work.",
        "You've got this. No doubt.",
        "The hard part is starting. You already did that!",
        "Stuck? That means you're learning.",
        "Bugs are just puzzles. And you love puzzles.",
        "You're building something cool. Don't forget that!",
    ]

    static let humor: [String] = [
        "I asked Claude for a joke but it used all our tokens.",
        "This code has more layers than an onion...",
        "Your code has its own weather system.",
        "A SQL query walks into a bar: 'Can I join you?'",
        "Why dark mode? Because light attracts bugs!",
        "There's no place like 127.0.0.1",
        "In JS, 0 == '0' is true. Trust issues!",
        "I'd tell you a UDP joke but you might not get it.",
        "My favorite pattern? Copy-Paste-Pray.",
        "Roses are #FF0000, violets are #0000FF...",
        "99 little bugs in the code, take one down...",
        "...patch it around, 127 little bugs in the code.",
        "I put the 'fun' in 'function'!",
        "Is it a stack overflow or a stack overflowing?",
        "Tabs vs spaces? Yes.",
        "My code doesn't have bugs. It has features.",
        "I'm not procrastinating, I'm doing research.",
        "Commit messages should tell a story. Yours is horror.",
        "404: motivation not found.",
        "Works on my machine. Ship the machine!",
        "I don't always test, but when I do, it's in prod.",
    ]

    // MARK: - Time-of-day phrases

    static func timeBasedPhrase() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9:
            return [
                "Good morning! Fresh start!",
                "Early bird gets the clean build!",
                "Coffee + code = magic.",
                "Rise and code!",
                "Morning! The bugs are still sleeping.",
            ].randomElement()
        case 9..<12:
            return [
                "Morning productivity peak — use it wisely!",
                "Great time to tackle the hard stuff.",
                "Peak brain hours. Go go go!",
                "The morning flow is real!",
            ].randomElement()
        case 12..<14:
            return [
                "Lunch break? Your brain needs fuel too!",
                "Afternoon coding session incoming!",
                "Food > code right now. Trust me.",
                "Post-lunch debugging? Brave.",
                "Eat something before the next refactor.",
            ].randomElement()
        case 14..<17:
            return [
                "Afternoon slump? Grab a snack!",
                "The 3pm wall is real. Push through!",
                "A coffee might help right about now.",
                "Afternoon mode: slow and steady.",
                "Almost there. End of day is in sight!",
            ].randomElement()
        case 17..<20:
            return [
                "It's past 5pm — got dinner plans?",
                "Evening mode. Wind down soon?",
                "You've earned a break.",
                "Maybe save the rest for tomorrow?",
                "Good work today. Seriously.",
            ].randomElement()
        case 20..<23:
            return [
                "Late night coding? Respect.",
                "Night owl mode activated.",
                "The bugs come out at night...",
                "Evening commits. The quiet ones.",
                "Stars are out. So are the bugs.",
            ].randomElement()
        case 23, 0..<5:
            return [
                "It's really late... you should sleep!",
                "Midnight oil isn't sustainable!",
                "Your pillow misses you.",
                "2am code is tomorrow's bug.",
                "Go. To. Sleep. Please.",
                "The code will still be here tomorrow.",
                "Nothing good happens after midnight... in code.",
            ].randomElement()
        default:
            // All hours 0-23 are covered above; default satisfies Swift exhaustiveness.
            return nil
        }
    }

    // MARK: - Day-of-week phrases

    static func dayBasedPhrase() -> String? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 2: // Monday
            return [
                "Monday motivation: let's crush it!",
                "New week, new chances to break prod.",
                "Monday energy. Channel it wisely.",
            ].randomElement()
        case 4: // Wednesday
            return [
                "Hump day! Downhill from here.",
                "Wednesday: halfway to the weekend!",
            ].randomElement()
        case 6: // Friday
            return [
                "Friday afternoon — ship it or shelve it!",
                "TGIF! Don't deploy on Friday though.",
                "Weekend's almost here!",
                "Friday rule: no new features after 3pm.",
            ].randomElement()
        case 7, 1: // Weekend
            return [
                "Weekend coding? That's dedication.",
                "Is this a passion project or a deadline?",
                "Weekend warriors. I respect it.",
                "Coding on the weekend? No judgment. Much respect.",
            ].randomElement()
        default:
            return nil
        }
    }

    // MARK: - Phrase dispatch

    /// Pick a mood-appropriate phrase, with character-specific overrides.
    static func moodPhrase(for mood: PetMood, character: PetCharacter = .clodey) -> String {
        // 40% chance of character-specific mood phrase (if one exists)
        if Int.random(in: 0..<10) < 4,
           let charPhrase = characterMoodPhrase(for: mood, character: character) {
            return charPhrase
        }
        let pool: [String]
        switch mood {
        case .ecstatic:  pool = ecstatic
        case .happy:     pool = happy
        case .normal:    pool = normal
        case .tired:     pool = tired
        case .exhausted: pool = exhausted
        case .critical:  pool = critical
        case .sleeping:  pool = sleeping
        case .reborn:    pool = reborn
        }
        return pool.randomElement() ?? "..."
    }

    /// Pick a random ambient phrase, mixing in character personality.
    static func randomAmbientPhrase(character: PetCharacter = .clodey, wellnessEnabled: Bool = true) -> String {
        // 10% chance of time-based, 5% chance of day-based
        let roll = Int.random(in: 0..<100)
        if roll < 10, let timeBased = timeBasedPhrase() {
            return timeBased
        }
        if roll < 15, let dayBased = dayBasedPhrase() {
            return dayBased
        }

        // 25% chance of character-specific personality phrase
        if roll < 40 {
            let personality = personalityPhrases(for: character)
            if let phrase = personality.randomElement() {
                return phrase
            }
        }

        let allAmbient = wellnessEnabled
            ? [wellness, codingWisdom, encouragement, humor]
            : [codingWisdom, encouragement, humor]
        let picked = allAmbient.randomElement() ?? humor
        return picked.randomElement() ?? "..."
    }

    /// Returns the personality phrase pool for a given character.
    static func personalityPhrases(for character: PetCharacter) -> [String] {
        switch character {
        case .clodey: return clodeyPersonality
        case .bytie:  return bytiePersonality
        case .sprout: return sproutPersonality
        case .ghosty: return ghostyPersonality
        }
    }

    // MARK: - Character mood dispatch (delegates to per-character extensions)

    static func characterMoodPhrase(for mood: PetMood, character: PetCharacter) -> String? {
        switch character {
        case .clodey: return clodeyMoodPhrase(for: mood)
        case .bytie:  return bytieMoodPhrase(for: mood)
        case .sprout: return sproutMoodPhrase(for: mood)
        case .ghosty: return ghostyMoodPhrase(for: mood)
        }
    }
}
