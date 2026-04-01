import Foundation

enum DiaryBodyFormat: String, Codable, CaseIterable, Identifiable {
    case markdown
    case html
    case latex
    case plain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .markdown:
            return "Markdown"
        case .html:
            return "HTML"
        case .latex:
            return "LaTeX"
        case .plain:
            return "Plain"
        }
    }
}

struct DiaryContentBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var attachments: [DiaryAttachment]

    init(id: UUID = UUID(), text: String = "", attachments: [DiaryAttachment] = []) {
        self.id = id
        self.text = text
        self.attachments = attachments
    }
}

struct DiaryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var selectedDate: Date
    var title: String
    var body: String
    var bodyFormat: DiaryBodyFormat
    var weather: WeatherOption
    var location: String?
    var tags: [String]
    var emotion: String?
    var attachments: [DiaryAttachment]
    var contentBlocks: [DiaryContentBlock]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        selectedDate: Date = Date(),
        title: String = "",
        body: String = "",
        bodyFormat: DiaryBodyFormat = .markdown,
        weather: WeatherOption = .sunny,
        location: String? = nil,
        tags: [String] = [],
        emotion: String? = nil,
        attachments: [DiaryAttachment] = [],
        contentBlocks: [DiaryContentBlock] = []
    ) {
        let normalizedBlocks = Self.normalizedBlocks(
            contentBlocks,
            fallbackBody: body,
            fallbackAttachments: attachments
        )
        self.id = id
        self.createdAt = createdAt
        self.selectedDate = selectedDate
        self.title = title
        self.body = Self.flattenBody(from: normalizedBlocks)
        self.bodyFormat = bodyFormat
        self.weather = weather
        self.location = location
        self.tags = tags
        self.emotion = emotion
        self.attachments = Self.flattenAttachments(from: normalizedBlocks)
        self.contentBlocks = normalizedBlocks
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case selectedDate
        case title
        case body
        case bodyFormat
        case weather
        case location
        case tag
        case tags
        case emotion
        case attachments
        case contentBlocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        selectedDate = try container.decodeIfPresent(Date.self, forKey: .selectedDate) ?? Date()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        let decodedBody = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        bodyFormat = try container.decodeIfPresent(DiaryBodyFormat.self, forKey: .bodyFormat) ?? .markdown
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
        let decodedAttachments = try container.decodeIfPresent([DiaryAttachment].self, forKey: .attachments) ?? []
        let decodedBlocks = try container.decodeIfPresent([DiaryContentBlock].self, forKey: .contentBlocks) ?? []
        let normalizedBlocks = Self.normalizedBlocks(
            decodedBlocks,
            fallbackBody: decodedBody,
            fallbackAttachments: decodedAttachments
        )
        body = Self.flattenBody(from: normalizedBlocks)
        attachments = Self.flattenAttachments(from: normalizedBlocks)
        contentBlocks = normalizedBlocks
    }

    func encode(to encoder: Encoder) throws {
        let normalizedBlocks = Self.normalizedBlocks(
            contentBlocks,
            fallbackBody: body,
            fallbackAttachments: attachments
        )
        let canonicalBody = Self.flattenBody(from: normalizedBlocks)
        let canonicalAttachments = Self.flattenAttachments(from: normalizedBlocks)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(selectedDate, forKey: .selectedDate)
        try container.encode(title, forKey: .title)
        try container.encode(canonicalBody, forKey: .body)
        try container.encode(bodyFormat, forKey: .bodyFormat)
        try container.encode(weather, forKey: .weather)
        try container.encodeIfPresent(location, forKey: .location)
        if let firstTag = tags.first {
            try container.encode(firstTag, forKey: .tag)
        }
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encode(canonicalAttachments, forKey: .attachments)
        try container.encode(normalizedBlocks, forKey: .contentBlocks)
    }

    private static func normalizedBlocks(
        _ blocks: [DiaryContentBlock],
        fallbackBody: String,
        fallbackAttachments: [DiaryAttachment]
    ) -> [DiaryContentBlock] {
        let filtered = blocks.filter { block in
            !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !block.attachments.isEmpty
        }
        if !filtered.isEmpty {
            return filtered
        }

        let trimmedBody = fallbackBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBody.isEmpty || !fallbackAttachments.isEmpty {
            return [DiaryContentBlock(text: fallbackBody, attachments: fallbackAttachments)]
        }

        return []
    }

    private static func flattenBody(from blocks: [DiaryContentBlock]) -> String {
        blocks
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func flattenAttachments(from blocks: [DiaryContentBlock]) -> [DiaryAttachment] {
        blocks.flatMap(\.attachments)
    }
}
