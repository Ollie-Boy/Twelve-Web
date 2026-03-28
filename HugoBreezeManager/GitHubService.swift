import Foundation

enum GitHubError: LocalizedError {
    case message(String)
    case invalidResponse
    case decodingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        case .invalidResponse:
            return "Invalid response from GitHub."
        case .decodingFailed:
            return "Unable to decode GitHub response."
        case .encodingFailed:
            return "Unable to encode request payload."
        }
    }
}

final class GitHubService {
    static let shared = GitHubService()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func startDeviceFlow(clientId: String) async throws -> DeviceCodeResponse {
        var request = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "client_id=\(clientId.urlEncoded)&scope=repo".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        guard let decoded = try? decoder.decode(DeviceCodeResponse.self, from: data) else {
            throw GitHubError.decodingFailed
        }
        return decoded
    }

    func pollDeviceToken(
        clientId: String,
        deviceCode: String,
        interval: Int,
        expiresIn: Int
    ) async throws -> String {
        let start = Date()
        var wait = interval

        while Date().timeIntervalSince(start) < Double(expiresIn) {
            try await Task.sleep(nanoseconds: UInt64(wait) * 1_000_000_000)

            var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = """
            client_id=\(clientId.urlEncoded)&device_code=\(deviceCode.urlEncoded)&grant_type=urn:ietf:params:oauth:grant-type:device_code
            """.data(using: .utf8)

            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)

            guard let tokenResponse = try? decoder.decode(AccessTokenResponse.self, from: data) else {
                throw GitHubError.decodingFailed
            }

            if let token = tokenResponse.accessToken {
                return token
            }

            switch tokenResponse.error {
            case "authorization_pending":
                continue
            case "slow_down":
                wait += 5
                continue
            case "expired_token":
                throw GitHubError.message("Device code expired. Start login again.")
            case "access_denied":
                throw GitHubError.message("GitHub login was denied.")
            case .some:
                throw GitHubError.message(tokenResponse.errorDescription ?? "GitHub login failed.")
            case .none:
                throw GitHubError.message("GitHub login failed.")
            }
        }

        throw GitHubError.message("GitHub login timed out.")
    }

    func fetchCurrentUser(token: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.httpMethod = "GET"
        addGitHubHeaders(token: token, to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        guard let user = try? decoder.decode(GitHubUser.self, from: data) else {
            throw GitHubError.decodingFailed
        }
        return user.login
    }

    func listPosts(token: String, settings: RepoSettings) async throws -> [GitHubFile] {
        let path = settings.normalizedContentPath.encodedPath
        let owner = settings.owner.urlPathComponent
        let repo = settings.repo.urlPathComponent
        let branch = settings.branch.urlQueryAllowed
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)?ref=\(branch)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addGitHubHeaders(token: token, to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        if let list = try? decoder.decode([GitHubFile].self, from: data) {
            return list
                .filter { $0.type == "file" && $0.name.isMarkdownFile }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        if let single = try? decoder.decode(GitHubFile.self, from: data) {
            guard single.type == "file", single.name.isMarkdownFile else { return [] }
            return [single]
        }
        throw GitHubError.decodingFailed
    }

    func getPost(token: String, settings: RepoSettings, path: String) async throws -> GitHubFileContent {
        let owner = settings.owner.urlPathComponent
        let repo = settings.repo.urlPathComponent
        let branch = settings.branch.urlQueryAllowed
        let endpointPath = path.encodedPath
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(endpointPath)?ref=\(branch)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addGitHubHeaders(token: token, to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        guard let remote = try? decoder.decode(GitHubFileContent.self, from: data) else {
            throw GitHubError.decodingFailed
        }

        let rawBase64 = remote.content.replacingOccurrences(of: "\n", with: "")
        guard
            let rawData = Data(base64Encoded: rawBase64),
            let markdown = String(data: rawData, encoding: .utf8)
        else {
            throw GitHubError.decodingFailed
        }

        return GitHubFileContent(sha: remote.sha, content: markdown, path: remote.path, name: remote.name)
    }

    func savePost(token: String, settings: RepoSettings, editor: EditorState) async throws {
        let owner = settings.owner.urlPathComponent
        let repo = settings.repo.urlPathComponent
        let path = editor.path.encodedPath
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        addGitHubHeaders(token: token, to: &request)

        guard let rawData = editor.content.data(using: .utf8) else {
            throw GitHubError.encodingFailed
        }

        let payload = GitHubWriteBody(
            message: editor.mode == .newPost
                ? "Create blog post \(editor.path.lastPathComponent)"
                : "Update blog post \(editor.path.lastPathComponent)",
            content: rawData.base64EncodedString(),
            branch: settings.branch,
            sha: editor.sha
        )
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    func deletePost(token: String, settings: RepoSettings, post: GitHubFile) async throws {
        let owner = settings.owner.urlPathComponent
        let repo = settings.repo.urlPathComponent
        let path = post.path.encodedPath
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addGitHubHeaders(token: token, to: &request)
        let payload = GitHubDeleteBody(
            message: "Delete blog post \(post.name)",
            sha: post.sha,
            branch: settings.branch
        )
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func addGitHubHeaders(token: String, to request: inout URLRequest) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func validate(response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            if
                let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let message = json["message"] as? String
            {
                throw GitHubError.message(message)
            }
            throw GitHubError.message("GitHub API error (\(http.statusCode)).")
        }
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    var urlPathComponent: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }

    var urlQueryAllowed: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    var encodedPath: String {
        split(separator: "/")
            .filter { !$0.isEmpty }
            .map { String($0).urlPathComponent }
            .joined(separator: "/")
    }

    var lastPathComponent: String {
        split(separator: "/").last.map(String.init) ?? self
    }

    var isMarkdownFile: Bool {
        lowercased().hasSuffix(".md") || lowercased().hasSuffix(".markdown")
    }
}
