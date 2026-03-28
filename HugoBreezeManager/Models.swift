import Foundation
import SwiftUI

struct RepoSettings: Codable {
    var owner: String = ""
    var repo: String = ""
    var branch: String = "main"
    var contentPath: String = "content/posts"

    var normalizedContentPath: String {
        contentPath
            .split(separator: "/")
            .map(String.init)
            .joined(separator: "/")
    }
}

struct AuthSession: Codable {
    var accessToken: String
    var clientId: String
}

struct GitHubFile: Codable, Identifiable, Hashable {
    var name: String
    var path: String
    var sha: String
    var type: String
    var id: String { sha }
}

struct GitHubFileContent: Codable {
    var sha: String
    var content: String
    var path: String
    var name: String
}

struct DeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    let interval: Int
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURI = "verification_uri"
        case interval
        case expiresIn = "expires_in"
    }
}

struct AccessTokenResponse: Codable {
    let accessToken: String?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
        case errorDescription = "error_description"
    }
}

struct GitHubUser: Codable {
    let login: String
}

enum EditorMode: String, Codable {
    case create
    case edit
}

struct EditorState: Identifiable, Codable, Hashable {
    var id = UUID()
    var mode: EditorMode
    var path: String
    var sha: String?
    var slug: String
    var content: String
}

extension Color {
    static let breezeBackground = Color(red: 245 / 255, green: 251 / 255, blue: 1.0)
    static let breezePrimary = Color(red: 115 / 255, green: 200 / 255, blue: 1.0)
    static let breezeSecondary = Color(red: 214 / 255, green: 239 / 255, blue: 1.0)
    static let breezeText = Color(red: 29 / 255, green: 55 / 255, blue: 80 / 255)
    static let breezeMuted = Color(red: 94 / 255, green: 122 / 255, blue: 147 / 255)
    static let breezeDanger = Color(red: 1.0, green: 124 / 255, blue: 139 / 255)
}

func slugify(_ input: String) -> String {
    let lowered = input.lowercased()
    let filtered = lowered.replacingOccurrences(
        of: "[^a-z0-9\\- ]",
        with: "",
        options: .regularExpression
    )
    let compactSpaces = filtered
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
    return compactSpaces.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
}

func templatePost(slug: String) -> String {
    """
    ---
    title: "\(slug.replacingOccurrences(of: "-", with: " "))"
    date: \(ISO8601DateFormatter().string(from: Date()))
    draft: false
    ---

    Write your cute and breezy story here.
    """
}
