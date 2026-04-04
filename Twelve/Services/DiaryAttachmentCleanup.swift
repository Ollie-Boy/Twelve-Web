import Foundation

enum DiaryAttachmentCleanup {
    /// Filenames (last path component) still referenced by any attachment in `entries`.
    static func referencedFileNames(entries: [DiaryEntry]) -> Set<String> {
        var set = Set<String>()
        for e in entries {
            for a in e.attachments {
                let name = (a.relativePath as NSString).lastPathComponent
                if !name.isEmpty { set.insert(name) }
            }
        }
        return set
    }

    /// Orphan files under Documents/DiaryAttachments (recursive flat folder).
    static func orphanURLs(entries: [DiaryEntry]) throws -> [URL] {
        let root = AttachmentService.attachmentsRootURL()
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        let refs = referencedFileNames(entries: entries)
        let inner = root.appendingPathComponent("DiaryAttachments", isDirectory: true)
        let scanURL = FileManager.default.fileExists(atPath: inner.path) ? inner : root
        let urls = try FileManager.default.contentsOfDirectory(at: scanURL, includingPropertiesForKeys: nil)
        return urls.filter { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return !isDir.boolValue && !refs.contains(url.lastPathComponent)
        }
    }

    static func attachmentDirectoryByteSize() -> Int64 {
        let root = AttachmentService.attachmentsRootURL()
        guard FileManager.default.fileExists(atPath: root.path) else { return 0 }
        return directorySize(at: root)
    }

    private static func directorySize(at url: URL) -> Int64 {
        var total: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else { return 0 }
        for case let fileURL as URL in enumerator {
            guard let vals = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  vals.isRegularFile == true,
                  let n = vals.fileSize
            else { continue }
            total += Int64(n)
        }
        return total
    }

    static func humanReadableSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1 { return String(format: "%.1f MB", mb) }
        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }
}
