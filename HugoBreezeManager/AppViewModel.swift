import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published var booting = true
    @Published var authBusy = false
    @Published var postsBusy = false
    @Published var savingBusy = false

    @Published var auth: AuthSession?
    @Published var clientIdInput = ""
    @Published var repoSettings = RepoSettings()
    @Published var username = ""
    @Published var posts: [GitHubFile] = []
    @Published var editor: EditorState?
    @Published var alertMessage: String?

    func bootstrap() async {
        defer { booting = false }
        do {
            auth = try SecureStore.loadAuth()
            repoSettings = try SecureStore.loadRepo() ?? RepoSettings()
            clientIdInput = auth?.clientId ?? ""

            if auth != nil {
                await refreshCurrentUser()
                await refreshPosts()
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func beginDeviceFlowLogin() async {
        let clientId = clientIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientId.isEmpty else {
            alertMessage = "Paste your GitHub OAuth App Client ID first."
            return
        }

        authBusy = true
        defer { authBusy = false }

        do {
            let device = try await GitHubService.shared.startDeviceFlow(clientId: clientId)
            guard let url = URL(string: device.verificationURI) else {
                throw GitHubError.message("Invalid GitHub verification URL.")
            }
            await UIApplication.shared.open(url)

            let token = try await GitHubService.shared.pollDeviceToken(
                clientId: clientId,
                deviceCode: device.deviceCode,
                interval: device.interval,
                expiresIn: device.expiresIn
            )
            let next = AuthSession(accessToken: token, clientId: clientId)
            auth = next
            try SecureStore.saveAuth(next)
            await refreshCurrentUser()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try SecureStore.clearAuth()
        } catch {
            alertMessage = error.localizedDescription
        }
        auth = nil
        username = ""
        posts = []
        editor = nil
    }

    func saveRepoSettings() async {
        repoSettings.owner = repoSettings.owner.trimmingCharacters(in: .whitespacesAndNewlines)
        repoSettings.repo = repoSettings.repo.trimmingCharacters(in: .whitespacesAndNewlines)
        repoSettings.branch = repoSettings.branch.trimmingCharacters(in: .whitespacesAndNewlines)
        repoSettings.contentPath = repoSettings.contentPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !repoSettings.owner.isEmpty, !repoSettings.repo.isEmpty else {
            alertMessage = "Owner and repository are required."
            return
        }

        do {
            try SecureStore.saveRepo(repoSettings)
            await refreshPosts()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func refreshCurrentUser() async {
        guard let auth else { return }
        do {
            username = try await GitHubService.shared.fetchCurrentUser(token: auth.accessToken)
        } catch {
            username = ""
            alertMessage = error.localizedDescription
        }
    }

    func refreshPosts() async {
        guard let auth else { return }
        guard !repoSettings.owner.isEmpty, !repoSettings.repo.isEmpty else { return }
        postsBusy = true
        defer { postsBusy = false }
        do {
            posts = try await GitHubService.shared.listPosts(token: auth.accessToken, settings: repoSettings)
        } catch {
            posts = []
            alertMessage = error.localizedDescription
        }
    }

    func createPostDraft() {
        let dateTag = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let draftSlug = "post-\(dateTag)"
        editor = EditorState(
            mode: .newPost,
            path: "\(repoSettings.normalizedContentPath)/\(draftSlug).md",
            sha: nil,
            slug: String(draftSlug),
            content: templatePost(slug: String(draftSlug))
        )
    }

    func openPost(_ file: GitHubFile) async {
        guard let auth else { return }
        postsBusy = true
        defer { postsBusy = false }
        do {
            let loaded = try await GitHubService.shared.getPost(
                token: auth.accessToken,
                settings: repoSettings,
                path: file.path
            )
            let slug = URL(fileURLWithPath: file.path).deletingPathExtension().lastPathComponent
            editor = EditorState(mode: .edit, path: file.path, sha: loaded.sha, slug: slug, content: loaded.content)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func updateEditorSlug(_ value: String) {
        guard var editor else { return }
        editor.slug = slugify(value)
        self.editor = editor
    }

    func updateEditorContent(_ value: String) {
        guard var editor else { return }
        editor.content = value
        self.editor = editor
    }

    func saveEditor() async {
        guard let auth else { return }
        guard var editor else { return }
        savingBusy = true
        defer { savingBusy = false }
        do {
            let finalSlug = slugify(editor.slug)
            guard !finalSlug.isEmpty else {
                throw GitHubError.message("Slug cannot be empty.")
            }
            editor.slug = finalSlug
            if editor.mode == .newPost {
                editor.path = "\(repoSettings.normalizedContentPath)/\(finalSlug).md"
            }

            try await GitHubService.shared.savePost(
                token: auth.accessToken,
                settings: repoSettings,
                editor: editor
            )

            self.editor = nil
            await refreshPosts()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func deletePost(_ file: GitHubFile) async {
        guard let auth else { return }
        savingBusy = true
        defer { savingBusy = false }
        do {
            try await GitHubService.shared.deletePost(token: auth.accessToken, settings: repoSettings, post: file)
            await refreshPosts()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
