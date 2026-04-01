import Foundation

struct DiaryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var selectedDate: Date
    var title: String
    var body: String
    var weather: WeatherOption
    var location: String?
    var tags: [String]
    var emotion: String?
    var attachments: [DiaryAttachment]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        selectedDate: Date = Date(),
        title: String = "",
        body: String = "",
        weather: WeatherOption = .sunny,
        location: String? = nil,
        tags: [String] = [],
        emotion: String? = nil,
        attachments: [DiaryAttachment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.selectedDate = selectedDate
        self.title = title
        self.body = body
        self.weather = weather
        self.location = location
        self.tags = tags
        self.emotion = emotion
        self.attachments = attachments
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case selectedDate
        case title
        case body
        case weather
        case location
        case tag
        case tags
        case emotion
        case attachments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        selectedDate = try container.decodeIfPresent(Date.self, forKey: .selectedDate) ?? Date()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        weather = try container.decodeIfPresent(WeatherOption.self, forKey: .weather) ?? .none
        location = try container.decodeIfPresent(String.self, forKey: .location)
        if let decodedTags = try container.decodeIfPresent([String].self, forKey: .tags) {
            tags = decodedTags
        } else if let legacyTag = try container.decodeIfPresent(String.self, forKey: .tag) {
            let trimmed = legacyTag.trimmingCharacters(in: .whitespacesAndNewlines)
            tags = trimmed.isEmpty ? [] : [trimmed]
        } else {
            tags = []
        }
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion)
        attachments = try container.decodeIfPresent([DiaryAttachment].self, forKey: .attachments) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(selectedDate, forKey: .selectedDate)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(weather, forKey: .weather)
        try container.encodeIfPresent(location, forKey: .location)
        if let firstTag = tags.first {
            try container.encode(firstTag, forKey: .tag)
        }
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encode(attachments, forKey: .attachments)
    }
}
