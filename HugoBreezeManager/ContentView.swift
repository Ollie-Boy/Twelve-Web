import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: AppViewModel
    @State private var bubbleA: CGFloat = -26
    @State private var bubbleB: CGFloat = 22
    @State private var bubbleC: CGFloat = -12

    var body: some View {
        ZStack {
            Color.breezeBackground.ignoresSafeArea()
            bubbleLayer

            if vm.booting {
                VStack(spacing: 12) {
                    ProgressView().tint(.breezePrimary)
                    Text("Warming up your blog manager...")
                        .foregroundStyle(.breezeMuted)
                }
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        heroCard
                        if vm.auth == nil {
                            loginCard
                        } else {
                            settingsCard
                            postsCard
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(item: $vm.editor) { _ in
            EditorView()
                .environmentObject(vm)
        }
        .alert("Error", isPresented: Binding(
            get: { vm.alertMessage != nil },
            set: { _ in vm.alertMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage ?? "")
        }
        .task {
            animateBubbles()
        }
    }

    private func animateBubbles() {
        withAnimation(.easeInOut(duration: 4.3).repeatForever(autoreverses: true)) {
            bubbleA = 24
        }
        withAnimation(.easeInOut(duration: 5.1).repeatForever(autoreverses: true)) {
            bubbleB = -30
        }
        withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
            bubbleC = 26
        }
    }

    private var bubbleLayer: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(Color.breezeSecondary.opacity(0.48))
                    .frame(width: 86, height: 86)
                    .offset(x: proxy.size.width * 0.17, y: bubbleA)
                Circle()
                    .fill(Color.breezePrimary.opacity(0.23))
                    .frame(width: 74, height: 74)
                    .offset(x: proxy.size.width * 0.62, y: bubbleB)
                Circle()
                    .fill(Color.breezeSecondary.opacity(0.34))
                    .frame(width: 58, height: 58)
                    .offset(x: proxy.size.width * 0.79, y: bubbleC)
            }
            .allowsHitTesting(false)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hugo Breeze Manager")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.breezeText)
            Text("Cute iPhone dashboard for your GitHub Pages Hugo blog.")
                .foregroundStyle(.breezeMuted)
            if !vm.username.isEmpty {
                Text("@\(vm.username)")
                    .font(.headline)
                    .foregroundStyle(.breezeText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.breezeSecondary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(Color.breezeSecondary, lineWidth: 1)
                .shadow(color: .breezePrimary.opacity(0.27), radius: 10, y: 5)
        )
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1) Link your GitHub account")
                .font(.title3.bold())
                .foregroundStyle(.breezeText)
            Text("Use your GitHub OAuth App Client ID. Device flow keeps client secret out of the app.")
                .foregroundStyle(.breezeMuted)

            TextField("GitHub OAuth Client ID", text: $vm.clientIdInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.breezeSecondary, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            BouncyButton(title: vm.authBusy ? "Linking..." : "Link GitHub", disabled: vm.authBusy) {
                Task { await vm.beginDeviceFlowLogin() }
            }
        }
        .cardStyle
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2) Blog repository settings")
                .font(.title3.bold())
                .foregroundStyle(.breezeText)

            breezeInput("Owner", text: Binding(
                get: { vm.repoSettings.owner },
                set: { vm.repoSettings.owner = $0 }
            ))
            breezeInput("Repository", text: Binding(
                get: { vm.repoSettings.repo },
                set: { vm.repoSettings.repo = $0 }
            ))
            breezeInput("Branch (main)", text: Binding(
                get: { vm.repoSettings.branch },
                set: { vm.repoSettings.branch = $0 }
            ))
            breezeInput("Hugo content path", text: Binding(
                get: { vm.repoSettings.contentPath },
                set: { vm.repoSettings.contentPath = $0 }
            ))

            HStack(spacing: 8) {
                BouncyButton(title: "Save settings") {
                    Task { await vm.saveRepoSettings() }
                }
                BouncyButton(title: "Sign out", variant: .ghost) {
                    vm.signOut()
                }
            }
        }
        .cardStyle
    }

    private var postsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("3) Manage Hugo posts")
                    .font(.title3.bold())
                    .foregroundStyle(.breezeText)
                Spacer()
                BouncyButton(title: "Refresh", variant: .ghost, disabled: vm.postsBusy) {
                    Task { await vm.refreshPosts() }
                }
            }

            BouncyButton(title: "+ New Post", disabled: vm.savingBusy) {
                vm.createPostDraft()
            }

            if vm.postsBusy {
                ProgressView().tint(.breezePrimary)
            } else if vm.posts.isEmpty {
                Text("No markdown files found. Save settings and create your first post.")
                    .foregroundStyle(.breezeMuted)
            } else {
                ForEach(vm.posts) { post in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.name)
                            .font(.headline)
                            .foregroundStyle(.breezeText)
                        Text(post.path)
                            .font(.caption)
                            .foregroundStyle(.breezeMuted)
                        HStack(spacing: 8) {
                            BouncyButton(title: "Edit", variant: .ghost) {
                                Task { await vm.openPost(post) }
                            }
                            BouncyButton(title: "Delete", variant: .danger) {
                                Task { await vm.deletePost(post) }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).stroke(Color.breezeSecondary, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .cardStyle
    }

    private func breezeInput(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Color.breezeSecondary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EditorView: View {
    @EnvironmentObject private var vm: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(vm.editor?.mode == .create ? "Create new post" : "Edit post")
                        .font(.title.bold())
                        .foregroundStyle(.breezeText)

                    if vm.editor?.mode == .create {
                        TextField("post-slug", text: Binding(
                            get: { vm.editor?.slug ?? "" },
                            set: { vm.updateEditorSlug($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).stroke(Color.breezeSecondary, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text(vm.editor?.path ?? "")
                        .font(.caption)
                        .foregroundStyle(.breezeMuted)

                    TextEditor(text: Binding(
                        get: { vm.editor?.content ?? "" },
                        set: { vm.updateEditorContent($0) }
                    ))
                    .frame(minHeight: 360)
                    .padding(8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(Color.breezeSecondary, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 8) {
                        BouncyButton(title: "Cancel", variant: .ghost) {
                            vm.editor = nil
                        }
                        BouncyButton(title: vm.savingBusy ? "Saving..." : "Save to GitHub", disabled: vm.savingBusy) {
                            Task { await vm.saveEditor() }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.breezeBackground)
            .navigationTitle("Editor")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private enum BreezeButtonVariant {
    case primary
    case ghost
    case danger
}

private struct BouncyButton: View {
    let title: String
    var variant: BreezeButtonVariant = .primary
    var disabled: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(backgroundColor)
                .clipShape(Capsule())
                .scaleEffect(pressed ? 0.94 : 1)
                .opacity(disabled ? 0.6 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: return .breezePrimary
        case .ghost: return .breezeSecondary
        case .danger: return .breezeDanger
        }
    }

    private var textColor: Color {
        variant == .danger ? .white : .breezeText
    }
}

private extension View {
    var cardStyle: some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.breezeSecondary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
