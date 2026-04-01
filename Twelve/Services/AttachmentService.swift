import Foundation
import UniformTypeIdentifiers

final class AttachmentService {
    private static let rootDirectoryName = "DiaryAttachments"

    func importPickedFiles(_ urls: [URL]) -> [DiaryAttachment] {
        urls.compactMap { try? importFile(from: $0) }
    }

    func importFile(from sourceURL: URL) throws -> DiaryAttachment {
        let attachmentsDir = try ensureAttachmentsDirectory()
        let ext = sourceURL.pathExtension
        let name = sourceURL.deletingPathExtension().lastPathComponent
        let safeName = name.replacingOccurrences(of: " ", with: "_")
        let destinationURL = attachmentsDir.appendingPathComponent("\(UUID().uuidString)_\(safeName).\(ext)")

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let kind = Self.resolveAttachmentKind(for: sourceURL)
        let relativePath = "\(Self.rootDirectoryName)/\(destinationURL.lastPathComponent)"
        return DiaryAttachment(
            fileName: sourceURL.lastPathComponent,
            relativePath: relativePath,
            kind: kind
        )
    }

    func importData(_ data: Data, fileName: String, kind: DiaryAttachmentKind) throws -> DiaryAttachment {
        let attachmentsDir = try ensureAttachmentsDirectory()
        let sanitizedName = fileName.replacingOccurrences(of: " ", with: "_")
        let destinationURL = attachmentsDir.appendingPathComponent("\(UUID().uuidString)_\(sanitizedName)")
        try data.write(to: destinationURL, options: .atomic)
        let relativePath = "\(Self.rootDirectoryName)/\(destinationURL.lastPathComponent)"
        return DiaryAttachment(
            fileName: fileName,
            relativePath: relativePath,
            kind: kind
        )
    }

    static func resolveAttachmentKind(for url: URL) -> DiaryAttachmentKind {
        let ext = url.pathExtension.lowercased()
        let type = UTType(filenameExtension: ext)

        if ext == "gif" { return .gif }
        if ext == "md" || ext == "markdown" { return .markdown }
        if ext == "tex" { return .latex }
        if type?.conforms(to: .image) == true { return .image }
        if type?.conforms(to: .movie) == true || type?.conforms(to: .video) == true { return .video }
        if type?.conforms(to: .audio) == true { return .audio }
        if type?.conforms(to: .text) == true || type?.conforms(to: .pdf) == true || type?.conforms(to: .json) == true { return .document }
        return .other
    }

    static func attachmentsRootURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent(Self.rootDirectoryName, isDirectory: true)
    }

    private func ensureAttachmentsDirectory() throws -> URL {
        let dir = Self.attachmentsRootURL().appendingPathComponent(Self.rootDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
