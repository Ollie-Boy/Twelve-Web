import SwiftUI
import UIKit
import WebKit

/// Renders diary body: native Markdown, HTML fragments, or Markdown/HTML mixed with LaTeX (WKWebView + MathJax).
struct DiaryBodyContentView: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var richWebHeight: CGFloat = 180

    var body: some View {
        Group {
            if let webMode = richWebMode {
                DiaryBodyRichWebView(
                    rawText: text,
                    mode: webMode,
                    isDark: colorScheme == .dark,
                    contentHeight: $richWebHeight
                )
                .frame(height: max(richWebHeight, 80))
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if looksLikeHTMLFragment(text) {
                HTMLFragmentTextView(htmlFragment: text, isDark: colorScheme == .dark)
            } else {
                NativeMarkdownTextView(text: text)
            }
        }
    }

    private var richWebMode: DiaryBodyRichWebView.PayloadMode? {
        guard containsLaTeXDelimiters(text) else { return nil }
        return looksLikeHTMLFragment(text) ? .rawHTML : .markdown
    }
}

// MARK: - LaTeX (narrow detection — do not block Markdown for `$` currency)

private func containsLaTeXDelimiters(_ s: String) -> Bool {
    if s.contains(#"\("#) || s.contains(#"\["#) { return true }
    if s.contains("$$") { return true }
    if let regex = try? NSRegularExpression(pattern: #"\$[^\$\s][^\$]*?\$"#, options: []) {
        let range = NSRange(s.startIndex..., in: s)
        return regex.firstMatch(in: s, options: [], range: range) != nil
    }
    return false
}

// MARK: - HTML detection

private func looksLikeHTMLFragment(_ s: String) -> Bool {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard t.count >= 6 else { return false }
    let lower = t.lowercased()
    if lower.hasPrefix("<!doctype") || lower.hasPrefix("<html") { return true }
    let pattern = #"<[\s/]?(p|div|span|br|h[1-6]|ul|ol|li|strong|b|em|i|a|table|tr|td|th|blockquote|pre|code|section|article|header|footer|nav)\b"#
    return t.range(of: pattern, options: .regularExpression) != nil
}

// MARK: - Native Markdown

private struct NativeMarkdownTextView: View {
    let text: String

    var body: some View {
        Group {
            if let attributed = Self.parsedMarkdown(text) {
                Text(attributed)
                    .font(BreezyTheme.appFont(size: 16))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(text)
                    .font(BreezyTheme.appFont(size: 16))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private static func parsedMarkdown(_ source: String) -> AttributedString? {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        return try? AttributedString(markdown: source, options: options)
    }
}

// MARK: - HTML → attributed text

private struct HTMLFragmentTextView: View {
    let htmlFragment: String
    let isDark: Bool

    var body: some View {
        Group {
            if let attributed = Self.attributedHTML(htmlFragment, isDark: isDark) {
                Text(attributed)
                    .font(BreezyTheme.appFont(size: 16))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(htmlFragment)
                    .font(BreezyTheme.appFont(size: 16))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .textSelection(.enabled)
            }
        }
    }

    private static func attributedHTML(_ fragment: String, isDark: Bool) -> AttributedString? {
        let textColor = isDark ? "#e8eaef" : "#1c1c1e"
        let wrapped = """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <style>
          body { font: -apple-system-body; font-size: 16px; line-height: 1.45; color: \(textColor); margin: 0; }
          a { color: #0a84ff; }
          pre, code { font-family: ui-monospace, Menlo, monospace; font-size: 14px; }
        </style></head><body>\(fragment)</body></html>
        """
        guard let data = wrapped.data(using: .utf8) else { return nil }
        guard let ns = try? NSMutableAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else { return nil }
        return AttributedString(ns)
    }
}

// MARK: - WKWebView: Markdown or HTML + MathJax

struct DiaryBodyRichWebView: UIViewRepresentable {
    enum PayloadMode {
        case markdown
        case rawHTML
    }

    let rawText: String
    let mode: PayloadMode
    let isDark: Bool
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "bodyHeight")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastRawText == rawText,
           context.coordinator.lastMode == mode,
           context.coordinator.lastIsDark == isDark {
            return
        }
        context.coordinator.lastRawText = rawText
        context.coordinator.lastMode = mode
        context.coordinator.lastIsDark = isDark

        let b64 = Data(rawText.utf8).base64EncodedString()
        let modeFlag = mode == .markdown ? "1" : "0"
        let bg = isDark ? "#0b0d12" : "#f5f7fb"
        let fg = isDark ? "#e8eaef" : "#1c1c1e"
        let codeBg = isDark ? "#161a22" : "#eef1f6"

        let html = """
        <!DOCTYPE html>
        <html><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
          body { margin: 0; padding: 0; font-family: -apple-system, system-ui; font-size: 16px; line-height: 1.45; color: \(fg); background: \(bg); }
          #content { padding: 2px 0; word-wrap: break-word; }
          pre { overflow-x: auto; padding: 10px; border-radius: 8px; background: \(codeBg); }
          code { font-family: ui-monospace, Menlo, monospace; font-size: 14px; }
          a { color: #0a84ff; }
          img { max-width: 100%; height: auto; }
        </style>
        <script>
          window.MathJax = {
            tex: {
              inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
              displayMath: [['$$','$$'], ['\\\\[','\\\\]']],
              processEscapes: true
            },
            options: { skipHtmlTags: ['script','noscript','style','textarea','pre'] }
          };
        </script>
        <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" async></script>
        </head><body>
        <div id="content"></div>
        <script>
          const payloadB64 = "\(b64)";
          const useMarkdown = "\(modeFlag)" === "1";
          function utf8FromB64(b64) {
            const bin = atob(b64);
            const bytes = new Uint8Array(bin.length);
            for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
            return new TextDecoder('utf-8').decode(bytes);
          }
          const raw = utf8FromB64(payloadB64);
          function notifyHeight() {
            const h = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
            window.webkit.messageHandlers.bodyHeight.postMessage(h);
          }
          function renderCore() {
            const el = document.getElementById('content');
            if (useMarkdown) {
              el.innerHTML = marked.parse(raw, { breaks: true, gfm: true });
            } else {
              el.innerHTML = raw;
            }
          }
          function runMathJax() {
            if (window.MathJax && MathJax.typesetPromise) {
              MathJax.typesetPromise([document.getElementById('content')]).then(notifyHeight).catch(notifyHeight);
            } else {
              let n = 0;
              const t = setInterval(function() {
                n++;
                if (window.MathJax && MathJax.typesetPromise) {
                  clearInterval(t);
                  MathJax.typesetPromise([document.getElementById('content')]).then(notifyHeight).catch(notifyHeight);
                } else if (n > 100) { clearInterval(t); notifyHeight(); }
              }, 40);
            }
          }
          if (useMarkdown) {
            let n = 0;
            const t = setInterval(function() {
              n++;
              if (typeof marked !== 'undefined') {
                clearInterval(t);
                renderCore();
                runMathJax();
              } else if (n > 100) { clearInterval(t); document.getElementById('content').textContent = raw; notifyHeight(); }
            }, 20);
          } else {
            renderCore();
            runMathJax();
          }
        </script>
        </body></html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "bodyHeight")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DiaryBodyRichWebView
        weak var webView: WKWebView?
        var lastRawText: String?
        var lastMode: PayloadMode?
        var lastIsDark: Bool?

        init(_ parent: DiaryBodyRichWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "bodyHeight" else { return }
            let value: CGFloat
            if let n = message.body as? Double {
                value = CGFloat(n)
            } else if let n = message.body as? NSNumber {
                value = CGFloat(truncating: n)
            } else {
                return
            }
            DispatchQueue.main.async {
                if value > 0 {
                    self.parent.contentHeight = value
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                if url.scheme == "http" || url.scheme == "https" {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
