import Foundation

enum DiaryWritingPromptStore {
    private static let enabledKey = "twelve.writingPrompt.enabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Deterministic by calendar day so the prompt stays stable for the day.
    static func prompt(for date: Date = Date()) -> String {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let idx = abs(day * 17 + cal.component(.year, from: date)) % prompts.count
        return prompts[idx]
    }

    private static let prompts: [String] = [
        "What made you smile today?",
        "One small thing you noticed.",
        "A sound or smell you remember from today.",
        "What would you tell a friend about today?",
        "Something you’re grateful for right now.",
        "A place you went (or wished you went).",
        "What tired you out — and what gave you energy?",
        "A tiny win from today.",
        "Weather and mood: how did they line up?",
        "One sentence about today, no editing.",
        "Who did you think of today?",
        "What are you looking forward to?",
        "Something you learned, even if small.",
        "A moment you’d like to keep.",
        "What would twelve-year-old you think of today?",
        "The sky today — did you look up?",
        "A food or drink that marked the day.",
        "What did your body feel like today?",
        "If today were a color, which one?",
        "One thing you’d do differently tomorrow.",
        "A song or line that fits today.",
        "What stayed calm today?",
        "Something unfinished — write one line about it.",
        "A message to next-week you.",
        "What felt light, like wind?",
    ]
}
