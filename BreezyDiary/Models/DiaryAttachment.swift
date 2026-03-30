import Foundation

enum DiaryAttachmentKind: String, Codable, Equatable {
    case image
    case video
    case gif
    case audio
    case markdown
    case latex
    case document
    case other
}

struct DiaryAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var fileName: String
    var relativePath: String
    var kind: DiaryAttachmentKind
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        relativePath: String,
        kind: DiaryAttachmentKind,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.relativePath = relativePath
        self.kind = kind
        self.createdAt = createdAt
    }

    var displayName: String {
        fileName
    }

    var iconName: String {
        kind.iconName
    }

    var url: URL {
        let root = AttachmentService.attachmentsRootURL()
        if relativePath.hasPrefix("DiaryAttachments/") {
            return root.appendingPathComponent(relativePath)
        }
        return root.appendingPathComponent("DiaryAttachments").appendingPathComponent(relativePath)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case relativePath
        case kind
        case createdAt
        // Backward compatibility keys from early model.
        case localPath
        case fileType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? "Attachment"

        if let path = try container.decodeIfPresent(String.self, forKey: .relativePath) {
            relativePath = path
        } else if let legacyLocalPath = try container.decodeIfPresent(String.self, forKey: .localPath) {
            let fileName = URL(fileURLWithPath: legacyLocalPath).lastPathComponent
            relativePath = fileName
        } else {
            relativePath = fileName
        }

        if let decodedKind = try container.decodeIfPresent(DiaryAttachmentKind.self, forKey: .kind) {
            kind = decodedKind
        } else if let legacyType = try container.decodeIfPresent(String.self, forKey: .fileType) {
            kind = DiaryAttachmentKind(rawValue: legacyType) ?? .other
        } else {
            kind = .other
        }
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(relativePath, forKey: .relativePath)
        try container.encode(kind, forKey: .kind)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// Keep compatibility with older references that used a lowercase "a" type name.
typealias Diaryattachment = DiaryAttachment

extension DiaryAttachmentKind {
    var iconName: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "video"
        case .gif:
            return "sparkles.tv"
        case .audio:
            return "waveform"
        case .markdown:
            return "doc.richtext"
        case .latex:
            return "function"
        case .document:
            return "doc.text"
        case .other:
            return "paperclip"
        }
    }
}
