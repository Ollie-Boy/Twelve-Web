import { StatusBar } from "expo-status-bar";
import * as SecureStore from "expo-secure-store";
import * as WebBrowser from "expo-web-browser";
import axios from "axios";
import { Base64 } from "js-base64";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Animated,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

WebBrowser.maybeCompleteAuthSession();

const AUTH_KEY = "hugobreeze.auth";
const REPO_KEY = "hugobreeze.repo";

const colors = {
  bg: "#f5fbff",
  card: "#ffffff",
  primary: "#73c8ff",
  secondary: "#d6efff",
  text: "#1d3750",
  muted: "#5e7a93",
  danger: "#ff7c8b",
};

type RepoSettings = {
  owner: string;
  repo: string;
  branch: string;
  contentPath: string;
};

type AuthSession = {
  accessToken: string;
  clientId: string;
};

type GitHubFile = {
  name: string;
  path: string;
  sha: string;
  type: string;
};

type EditorState = {
  mode: "new" | "edit";
  path: string;
  sha?: string;
  slug: string;
  content: string;
};

const defaultRepoSettings: RepoSettings = {
  owner: "",
  repo: "",
  branch: "main",
  contentPath: "content/posts",
};

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const encodePath = (path: string) =>
  path
    .split("/")
    .filter(Boolean)
    .map((segment) => encodeURIComponent(segment))
    .join("/");

const normalizePath = (path: string) =>
  path
    .split("/")
    .filter(Boolean)
    .join("/");

const baseName = (path: string) => path.split("/").pop() ?? path;

const slugify = (value: string) =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9- ]/g, "")
    .trim()
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");

const templatePost = (slug: string) => `---
title: "${slug.replace(/-/g, " ")}"
date: ${new Date().toISOString()}
draft: false
---

Write your cute and breezy story here.
`;

function readError(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const apiMessage =
      (error.response?.data as { message?: string } | undefined)?.message ??
      (error.response?.data as { error_description?: string } | undefined)
        ?.error_description;
    return apiMessage ?? error.message;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return "Unknown error";
}

function BouncyButton({
  title,
  onPress,
  disabled,
  variant = "primary",
}: {
  title: string;
  onPress: () => void;
  disabled?: boolean;
  variant?: "primary" | "ghost" | "danger";
}) {
  const scale = useRef(new Animated.Value(1)).current;

  const bgColor =
    variant === "ghost"
      ? "#eaf7ff"
      : variant === "danger"
        ? colors.danger
        : colors.primary;
  const txtColor = variant === "danger" ? "#ffffff" : colors.text;

  return (
    <Pressable
      disabled={disabled}
      onPressIn={() =>
        Animated.spring(scale, {
          toValue: 0.95,
          useNativeDriver: true,
          friction: 6,
          tension: 120,
        }).start()
      }
      onPressOut={() =>
        Animated.spring(scale, {
          toValue: 1,
          useNativeDriver: true,
          friction: 5,
          tension: 100,
        }).start()
      }
      onPress={onPress}
      style={styles.buttonShell}
    >
      <Animated.View
        style={[
          styles.button,
          { transform: [{ scale }], backgroundColor: bgColor },
          disabled && styles.buttonDisabled,
        ]}
      >
        <Text style={[styles.buttonText, { color: txtColor }]}>{title}</Text>
      </Animated.View>
    </Pressable>
  );
}

function FloatingBubbles() {
  const bubbles = useRef([
    new Animated.Value(0),
    new Animated.Value(0),
    new Animated.Value(0),
    new Animated.Value(0),
  ]).current;

  useEffect(() => {
    const animations = bubbles.map((value, idx) =>
      Animated.loop(
        Animated.sequence([
          Animated.timing(value, {
            toValue: 1,
            duration: 4200 + idx * 700,
            useNativeDriver: true,
          }),
          Animated.timing(value, {
            toValue: 0,
            duration: 3800 + idx * 500,
            useNativeDriver: true,
          }),
        ])
      )
    );
    animations.forEach((animation) => animation.start());
    return () => animations.forEach((animation) => animation.stop());
  }, [bubbles]);

  return (
    <View style={styles.bubbleLayer} pointerEvents="none">
      {bubbles.map((bubble, idx) => (
        <Animated.View
          key={`bubble-${idx}`}
          style={[
            styles.bubble,
            {
              left: `${12 + idx * 22}%`,
              transform: [
                {
                  translateY: bubble.interpolate({
                    inputRange: [0, 1],
                    outputRange: [20 + idx * 8, -26 - idx * 8],
                  }),
                },
                {
                  scale: bubble.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0.9, 1.15],
                  }),
                },
              ],
              opacity: bubble.interpolate({
                inputRange: [0, 1],
                outputRange: [0.3, 0.68],
              }),
            },
          ]}
        />
      ))}
    </View>
  );
}

export default function App() {
  const [booting, setBooting] = useState(true);
  const [auth, setAuth] = useState<AuthSession | null>(null);
  const [clientIdInput, setClientIdInput] = useState("");
  const [repoSettings, setRepoSettings] = useState(defaultRepoSettings);
  const [username, setUsername] = useState("");

  const [authBusy, setAuthBusy] = useState(false);
  const [postsBusy, setPostsBusy] = useState(false);
  const [savingBusy, setSavingBusy] = useState(false);

  const [posts, setPosts] = useState<GitHubFile[]>([]);
  const [editor, setEditor] = useState<EditorState | null>(null);

  const github = useMemo(() => {
    if (!auth?.accessToken) {
      return null;
    }
    return axios.create({
      baseURL: "https://api.github.com",
      headers: {
        Authorization: `Bearer ${auth.accessToken}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
    });
  }, [auth?.accessToken]);

  useEffect(() => {
    const init = async () => {
      try {
        const authRaw = await SecureStore.getItemAsync(AUTH_KEY);
        const repoRaw = await SecureStore.getItemAsync(REPO_KEY);

        if (authRaw) {
          const parsed = JSON.parse(authRaw) as AuthSession;
          setAuth(parsed);
          setClientIdInput(parsed.clientId);
        }
        if (repoRaw) {
          const parsed = JSON.parse(repoRaw) as RepoSettings;
          setRepoSettings({
            ...defaultRepoSettings,
            ...parsed,
          });
        }
      } catch (error) {
        Alert.alert("Load issue", readError(error));
      } finally {
        setBooting(false);
      }
    };
    void init();
  }, []);

  useEffect(() => {
    const fetchUser = async () => {
      if (!github) {
        setUsername("");
        return;
      }
      try {
        const result = await github.get("/user");
        setUsername(result.data.login ?? "");
      } catch {
        setUsername("");
      }
    };
    void fetchUser();
  }, [github]);

  const refreshPosts = async (incoming?: RepoSettings) => {
    if (!github) {
      return;
    }
    const active = incoming ?? repoSettings;
    if (!active.owner.trim() || !active.repo.trim()) {
      return;
    }
    setPostsBusy(true);
    try {
      const endpoint = `/repos/${encodeURIComponent(
        active.owner.trim()
      )}/${encodeURIComponent(active.repo.trim())}/contents/${encodePath(
        normalizePath(active.contentPath)
      )}`;
      const result = await github.get(endpoint, {
        params: { ref: active.branch.trim() || "main" },
      });

      const items: GitHubFile[] = (Array.isArray(result.data)
        ? result.data
        : [result.data]
      ).filter(
        (entry: GitHubFile) =>
          entry.type === "file" &&
          (entry.name.endsWith(".md") || entry.name.endsWith(".markdown"))
      );

      items.sort((a, b) => a.name.localeCompare(b.name));
      setPosts(items);
    } catch (error) {
      setPosts([]);
      Alert.alert("Could not load posts", readError(error));
    } finally {
      setPostsBusy(false);
    }
  };

  const saveRepoSettings = async () => {
    const normalized: RepoSettings = {
      owner: repoSettings.owner.trim(),
      repo: repoSettings.repo.trim(),
      branch: repoSettings.branch.trim() || "main",
      contentPath: normalizePath(repoSettings.contentPath || "content/posts"),
    };
    if (!normalized.owner || !normalized.repo) {
      Alert.alert("Missing data", "Owner and repo are required.");
      return;
    }
    try {
      await SecureStore.setItemAsync(REPO_KEY, JSON.stringify(normalized));
      setRepoSettings(normalized);
      await refreshPosts(normalized);
    } catch (error) {
      Alert.alert("Save issue", readError(error));
    }
  };

  const beginDeviceFlowLogin = async () => {
    const clientId = clientIdInput.trim();
    if (!clientId) {
      Alert.alert("Client ID needed", "Paste your GitHub OAuth App Client ID.");
      return;
    }

    setAuthBusy(true);
    try {
      const deviceRes = await axios.post(
        "https://github.com/login/device/code",
        `client_id=${encodeURIComponent(clientId)}&scope=${encodeURIComponent(
          "repo"
        )}`,
        {
          headers: {
            Accept: "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
          },
        }
      );

      const {
        device_code: deviceCode,
        user_code: userCode,
        verification_uri: verificationUri,
        interval,
        expires_in: expiresIn,
      } = deviceRes.data as {
        device_code: string;
        user_code: string;
        verification_uri: string;
        interval: number;
        expires_in: number;
      };

      Alert.alert(
        "Finish login in browser",
        `Enter code ${userCode} on GitHub.`
      );

      await WebBrowser.openBrowserAsync(verificationUri);

      const started = Date.now();
      let waitSeconds = interval;
      let token = "";

      while (Date.now() - started < expiresIn * 1000) {
        await sleep(waitSeconds * 1000);
        const tokenRes = await axios.post(
          "https://github.com/login/oauth/access_token",
          `client_id=${encodeURIComponent(
            clientId
          )}&device_code=${encodeURIComponent(
            deviceCode
          )}&grant_type=urn:ietf:params:oauth:grant-type:device_code`,
          {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/x-www-form-urlencoded",
            },
          }
        );

        if (tokenRes.data.access_token) {
          token = tokenRes.data.access_token;
          break;
        }

        const code = tokenRes.data.error;
        if (code === "authorization_pending") {
          continue;
        }
        if (code === "slow_down") {
          waitSeconds += 5;
          continue;
        }
        if (code === "expired_token") {
          throw new Error("Code expired. Please start login again.");
        }
        if (code === "access_denied") {
          throw new Error("GitHub login was denied.");
        }

        throw new Error(tokenRes.data.error_description ?? "Login failed.");
      }

      if (!token) {
        throw new Error("Login timed out. Try again.");
      }

      const nextAuth: AuthSession = { accessToken: token, clientId };
      setAuth(nextAuth);
      await SecureStore.setItemAsync(AUTH_KEY, JSON.stringify(nextAuth));
    } catch (error) {
      Alert.alert("Login failed", readError(error));
    } finally {
      setAuthBusy(false);
    }
  };

  const signOut = async () => {
    await SecureStore.deleteItemAsync(AUTH_KEY);
    setAuth(null);
    setPosts([]);
    setUsername("");
  };

  const createPostDraft = () => {
    const draftSlug = slugify(`post-${new Date().toISOString().slice(0, 10)}`);
    const fullPath = `${normalizePath(repoSettings.contentPath)}/${draftSlug}.md`;
    setEditor({
      mode: "new",
      path: fullPath,
      slug: draftSlug,
      content: templatePost(draftSlug),
    });
  };

  const openPost = async (item: GitHubFile) => {
    if (!github) {
      return;
    }
    setPostsBusy(true);
    try {
      const endpoint = `/repos/${encodeURIComponent(
        repoSettings.owner
      )}/${encodeURIComponent(repoSettings.repo)}/contents/${encodePath(
        item.path
      )}`;
      const result = await github.get(endpoint, {
        params: { ref: repoSettings.branch },
      });
      const decoded = Base64.decode((result.data.content as string).replace(/\n/g, ""));
      setEditor({
        mode: "edit",
        path: item.path,
        slug: baseName(item.path).replace(/\.(md|markdown)$/i, ""),
        sha: result.data.sha,
        content: decoded,
      });
    } catch (error) {
      Alert.alert("Could not open post", readError(error));
    } finally {
      setPostsBusy(false);
    }
  };

  const saveEditor = async () => {
    if (!github || !editor) {
      return;
    }
    setSavingBusy(true);
    try {
      const finalSlug = slugify(editor.slug) || "untitled-post";
      const finalPath =
        editor.mode === "new"
          ? `${normalizePath(repoSettings.contentPath)}/${finalSlug}.md`
          : editor.path;
      const endpoint = `/repos/${encodeURIComponent(
        repoSettings.owner
      )}/${encodeURIComponent(repoSettings.repo)}/contents/${encodePath(
        finalPath
      )}`;

      await github.put(endpoint, {
        message:
          editor.mode === "new"
            ? `Create blog post ${baseName(finalPath)}`
            : `Update blog post ${baseName(finalPath)}`,
        content: Base64.encode(editor.content),
        branch: repoSettings.branch,
        ...(editor.mode === "edit" && editor.sha ? { sha: editor.sha } : {}),
      });

      setEditor(null);
      await refreshPosts();
    } catch (error) {
      Alert.alert("Save failed", readError(error));
    } finally {
      setSavingBusy(false);
    }
  };

  const deletePost = (item: GitHubFile) => {
    if (!github) {
      return;
    }
    Alert.alert("Delete this post?", item.name, [
      { text: "Cancel", style: "cancel" },
      {
        text: "Delete",
        style: "destructive",
        onPress: () => {
          void (async () => {
            setSavingBusy(true);
            try {
              const endpoint = `/repos/${encodeURIComponent(
                repoSettings.owner
              )}/${encodeURIComponent(repoSettings.repo)}/contents/${encodePath(
                item.path
              )}`;
              await github.delete(endpoint, {
                data: {
                  message: `Delete blog post ${item.name}`,
                  sha: item.sha,
                  branch: repoSettings.branch,
                },
              });
              await refreshPosts();
            } catch (error) {
              Alert.alert("Delete failed", readError(error));
            } finally {
              setSavingBusy(false);
            }
          })();
        },
      },
    ]);
  };

  if (booting) {
    return (
      <SafeAreaView style={styles.root}>
        <FloatingBubbles />
        <View style={styles.center}>
          <ActivityIndicator color={colors.primary} size="large" />
          <Text style={styles.mutedText}>Warming up your blog manager...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar style="dark" />
      <FloatingBubbles />

      <ScrollView
        contentContainerStyle={styles.scrollBody}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.heroCard}>
          <Text style={styles.heroTitle}>Hugo Breeze Manager</Text>
          <Text style={styles.heroSubtitle}>
            Cute iPhone control panel for your GitHub Pages blog.
          </Text>
          {!!username && <Text style={styles.badge}>@{username}</Text>}
        </View>

        {!auth ? (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>1) Link your GitHub account</Text>
            <Text style={styles.bodyText}>
              Use a GitHub OAuth App Client ID. This app uses device login, so
              no client secret is stored on your phone.
            </Text>
            <TextInput
              placeholder="GitHub OAuth Client ID"
              value={clientIdInput}
              onChangeText={setClientIdInput}
              autoCapitalize="none"
              style={styles.input}
            />
            <BouncyButton
              title={authBusy ? "Linking..." : "Link GitHub"}
              onPress={() => void beginDeviceFlowLogin()}
              disabled={authBusy}
            />
          </View>
        ) : (
          <>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>2) Blog repository settings</Text>
              <TextInput
                placeholder="Owner (e.g. your GitHub username)"
                value={repoSettings.owner}
                onChangeText={(owner) =>
                  setRepoSettings((prev) => ({ ...prev, owner }))
                }
                autoCapitalize="none"
                style={styles.input}
              />
              <TextInput
                placeholder="Repository name"
                value={repoSettings.repo}
                onChangeText={(repo) =>
                  setRepoSettings((prev) => ({ ...prev, repo }))
                }
                autoCapitalize="none"
                style={styles.input}
              />
              <TextInput
                placeholder="Branch (default main)"
                value={repoSettings.branch}
                onChangeText={(branch) =>
                  setRepoSettings((prev) => ({ ...prev, branch }))
                }
                autoCapitalize="none"
                style={styles.input}
              />
              <TextInput
                placeholder="Hugo content path (default content/posts)"
                value={repoSettings.contentPath}
                onChangeText={(contentPath) =>
                  setRepoSettings((prev) => ({ ...prev, contentPath }))
                }
                autoCapitalize="none"
                style={styles.input}
              />
              <View style={styles.row}>
                <BouncyButton
                  title="Save settings"
                  onPress={() => void saveRepoSettings()}
                />
                <BouncyButton title="Sign out" onPress={() => void signOut()} variant="ghost" />
              </View>
            </View>

            <View style={styles.card}>
              <View style={styles.rowSpace}>
                <Text style={styles.cardTitle}>3) Manage Hugo posts</Text>
                <BouncyButton
                  title="Refresh"
                  variant="ghost"
                  onPress={() => void refreshPosts()}
                  disabled={postsBusy}
                />
              </View>
              <BouncyButton
                title="+ New Post"
                onPress={createPostDraft}
                disabled={savingBusy}
              />
              {postsBusy ? (
                <ActivityIndicator style={styles.loader} color={colors.primary} />
              ) : posts.length === 0 ? (
                <Text style={styles.bodyText}>
                  No markdown files found yet. Save repo settings and create your
                  first post.
                </Text>
              ) : (
                posts.map((item) => (
                  <View key={item.sha} style={styles.postRow}>
                    <View style={styles.postTextWrap}>
                      <Text style={styles.postName}>{item.name}</Text>
                      <Text style={styles.postPath}>{item.path}</Text>
                    </View>
                    <View style={styles.rowTight}>
                      <BouncyButton
                        title="Edit"
                        variant="ghost"
                        onPress={() => void openPost(item)}
                      />
                      <BouncyButton
                        title="Delete"
                        variant="danger"
                        onPress={() => deletePost(item)}
                      />
                    </View>
                  </View>
                ))
              )}
            </View>
          </>
        )}
      </ScrollView>

      <Modal visible={!!editor} animationType="slide">
        <SafeAreaView style={styles.modalRoot}>
          <KeyboardAvoidingView
            behavior={Platform.OS === "ios" ? "padding" : undefined}
            style={styles.modalRoot}
          >
            <ScrollView contentContainerStyle={styles.modalScroll}>
              <Text style={styles.modalTitle}>
                {editor?.mode === "new" ? "Create new post" : "Edit post"}
              </Text>
              {editor?.mode === "new" && (
                <TextInput
                  style={styles.input}
                  placeholder="post-slug"
                  value={editor.slug}
                  onChangeText={(slug) =>
                    setEditor((prev) =>
                      prev ? { ...prev, slug: slugify(slug) } : prev
                    )
                  }
                  autoCapitalize="none"
                />
              )}
              <Text style={styles.pathLabel}>{editor?.path}</Text>
              <TextInput
                multiline
                textAlignVertical="top"
                style={styles.editorInput}
                value={editor?.content ?? ""}
                onChangeText={(content) =>
                  setEditor((prev) => (prev ? { ...prev, content } : prev))
                }
                placeholder="Markdown content..."
              />
              <View style={styles.row}>
                <BouncyButton
                  title="Cancel"
                  variant="ghost"
                  onPress={() => setEditor(null)}
                />
                <BouncyButton
                  title={savingBusy ? "Saving..." : "Save to GitHub"}
                  onPress={() => void saveEditor()}
                  disabled={savingBusy}
                />
              </View>
            </ScrollView>
          </KeyboardAvoidingView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
  },
  scrollBody: {
    padding: 16,
    gap: 14,
    paddingBottom: 40,
  },
  heroCard: {
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 16,
    borderWidth: 1,
    borderColor: "#d0ecff",
    shadowColor: "#8ecfff",
    shadowOpacity: 0.2,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  heroTitle: {
    fontSize: 24,
    fontWeight: "800",
    color: colors.text,
  },
  heroSubtitle: {
    marginTop: 6,
    color: colors.muted,
  },
  badge: {
    alignSelf: "flex-start",
    marginTop: 10,
    backgroundColor: colors.secondary,
    color: colors.text,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    overflow: "hidden",
    fontWeight: "700",
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "#d9f0ff",
    padding: 14,
    gap: 10,
  },
  cardTitle: {
    color: colors.text,
    fontWeight: "800",
    fontSize: 18,
  },
  bodyText: {
    color: colors.muted,
    lineHeight: 20,
  },
  mutedText: {
    color: colors.muted,
  },
  input: {
    borderWidth: 1,
    borderColor: "#b7e2ff",
    backgroundColor: "#f9fdff",
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 11,
    color: colors.text,
  },
  row: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  rowSpace: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    gap: 8,
  },
  rowTight: {
    flexDirection: "row",
    gap: 6,
    flexWrap: "wrap",
  },
  buttonShell: {
    alignSelf: "flex-start",
  },
  button: {
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    fontWeight: "800",
    fontSize: 14,
  },
  postRow: {
    borderWidth: 1,
    borderColor: "#d8edff",
    borderRadius: 14,
    padding: 10,
    backgroundColor: "#fafdff",
    gap: 8,
  },
  postTextWrap: {
    gap: 2,
  },
  postName: {
    color: colors.text,
    fontWeight: "700",
  },
  postPath: {
    color: colors.muted,
    fontSize: 12,
  },
  loader: {
    marginVertical: 12,
  },
  modalRoot: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  modalScroll: {
    padding: 16,
    gap: 10,
    paddingBottom: 30,
  },
  modalTitle: {
    color: colors.text,
    fontWeight: "800",
    fontSize: 22,
  },
  pathLabel: {
    color: colors.muted,
    fontSize: 12,
  },
  editorInput: {
    minHeight: 320,
    borderWidth: 1,
    borderColor: "#b6e4ff",
    borderRadius: 12,
    padding: 12,
    backgroundColor: "#ffffff",
    color: colors.text,
    fontSize: 15,
    lineHeight: 22,
  },
  bubbleLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  bubble: {
    position: "absolute",
    width: 66,
    height: 66,
    borderRadius: 999,
    top: "18%",
    backgroundColor: "#bce5ff",
  },
});
