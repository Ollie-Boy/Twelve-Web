import SwiftUI
import UIKit
import WebKit

/// Renders diary body via WKWebView (Markdown and/or HTML) with optional offline MathJax for LaTeX.
struct DiaryBodyContentView: View {
    let text: String
    /// When set, caps height and enables vertical scrolling inside the web view (e.g. list card preview).
    var compactMaxHeight: CGFloat?
    @Environment(\.colorScheme) private var colorScheme
    @State private var richWebHeight: CGFloat = 160

    var body: some View {
        let natural = max(richWebHeight, compactMaxHeight.map { _ in 60 } ?? 80)
        let cappedHeight: CGFloat = {
            guard let cap = compactMaxHeight else { return natural }
            return min(natural, cap)
        }()

        DiaryBodyRichWebView(
            rawText: text,
            mode: looksLikeHTMLFragment(text) ? .rawHTML : .markdown,
            isDark: colorScheme == .dark,
            includeMathJax: containsLaTeXDelimiters(text),
            compactMaxHeight: compactMaxHeight,
            contentHeight: $richWebHeight
        )
        .frame(height: cappedHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

// MARK: - LaTeX

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

// MARK: - Bundle script URLs (offline)

private enum DiaryBodyWebAssets {
    static var baseDirectoryURL: URL? {
        Bundle.main.bundleURL
    }

    static var markedScriptURL: URL? {
        Bundle.main.url(forResource: "marked.min", withExtension: "js")
    }

    static var mathJaxScriptURL: URL? {
        Bundle.main.url(forResource: "mathjax-tex-svg", withExtension: "js")
    }
}

// MARK: - WKWebView

struct DiaryBodyRichWebView: UIViewRepresentable {
    enum PayloadMode {
        case markdown
        case rawHTML
    }

    let rawText: String
    let mode: PayloadMode
    let isDark: Bool
    let includeMathJax: Bool
    var compactMaxHeight: CGFloat?
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
        let scroll = webView.scrollView
        scroll.backgroundColor = .clear
        scroll.isScrollEnabled = compactMaxHeight != nil
        scroll.bounces = false
        scroll.showsVerticalScrollIndicator = compactMaxHeight == nil
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        webView.scrollView.isScrollEnabled = compactMaxHeight != nil
        webView.scrollView.showsVerticalScrollIndicator = compactMaxHeight == nil

        if context.coordinator.lastRawText == rawText,
           context.coordinator.lastMode == mode,
           context.coordinator.lastIsDark == isDark,
           context.coordinator.lastIncludeMathJax == includeMathJax,
           context.coordinator.lastCompact == compactMaxHeight {
            return
        }
        context.coordinator.lastRawText = rawText
        context.coordinator.lastMode = mode
        context.coordinator.lastIsDark = isDark
        context.coordinator.lastIncludeMathJax = includeMathJax
        context.coordinator.lastCompact = compactMaxHeight

        let b64 = Data(rawText.utf8).base64EncodedString()
        let modeFlag = mode == .markdown ? "1" : "0"
        let mathFlag = includeMathJax ? "1" : "0"
        let fg = isDark ? "#e8eaef" : "#1c1c1e"
        let codeFg = isDark ? "#c8ccd4" : "#3a3a3c"
        let linkColor = isDark ? "#64a8ff" : "#007aff"
        let borderSubtle = isDark ? "rgba(255,255,255,0.12)" : "rgba(0,0,0,0.08)"

        let markedTag: String
        if mode == .markdown, let markedURL = DiaryBodyWebAssets.markedScriptURL {
            markedTag = "<script src=\"\(markedURL.lastPathComponent)\"></script>"
        } else {
            markedTag = ""
        }

        let mathJaxTag: String
        if includeMathJax, let mjURL = DiaryBodyWebAssets.mathJaxScriptURL {
            mathJaxTag = """
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
            <script src="\(mjURL.lastPathComponent)"></script>
            """
        } else {
            mathJaxTag = ""
        }

        let bodyFontStack = BreezyTheme.webContentFontFamilyCSS
        let html = """
        <!DOCTYPE html>
        <html><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
          html, body { margin: 0; padding: 0; background: transparent !important; }
          body {
            font-family: \(bodyFontStack);
            font-size: 16px;
            line-height: 1.45;
            color: \(fg);
          }
          #content { padding: 2px 0; word-wrap: break-word; }
          pre, code {
            font-family: \(bodyFontStack);
            font-size: 14px;
            color: \(codeFg);
            background: transparent !important;
          }
          pre {
            margin: 0.6em 0;
            padding: 0;
            overflow-x: auto;
            border-left: 3px solid \(borderSubtle);
            padding-left: 10px;
          }
          code { padding: 0; border-radius: 0; }
          pre code { border: none; display: block; white-space: pre; }
          p { margin: 0.35em 0; }
          ul, ol { margin: 0.35em 0; padding-left: 1.35em; }
          h1, h2, h3, h4 { font-family: \(bodyFontStack); font-weight: 600; margin: 0.5em 0 0.25em; line-height: 1.25; }
          h1 { font-size: 1.35em; } h2 { font-size: 1.2em; } h3 { font-size: 1.08em; }
          blockquote {
            margin: 0.5em 0;
            padding-left: 12px;
            border-left: 3px solid \(borderSubtle);
            color: \(fg);
            opacity: 0.92;
          }
          a { color: \(linkColor); }
          img { max-width: 100%; height: auto; }
          table { border-collapse: collapse; width: 100%; font-size: 15px; }
          th, td { border: 1px solid \(borderSubtle); padding: 6px 8px; }
        </style>
        \(markedTag)
        \(mathJaxTag)
        </head><body>
        <div id="content"></div>
        <script>
          const payloadB64 = "\(b64)";
          const useMarkdown = "\(modeFlag)" === "1";
          const useMathJax = "\(mathFlag)" === "1";
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
            if (useMarkdown && typeof marked !== 'undefined') {
              el.innerHTML = marked.parse(raw, { breaks: true, gfm: true });
            } else if (useMarkdown) {
              el.textContent = raw;
            } else {
              el.innerHTML = raw;
            }
          }
          function runMathJax() {
            if (!useMathJax) { notifyHeight(); return; }
            if (window.MathJax && MathJax.typesetPromise) {
              MathJax.typesetPromise([document.getElementById('content')]).then(notifyHeight).catch(notifyHeight);
            } else {
              let n = 0;
              const t = setInterval(function() {
                n++;
                if (window.MathJax && MathJax.typesetPromise) {
                  clearInterval(t);
                  MathJax.typesetPromise([document.getElementById('content')]).then(notifyHeight).catch(notifyHeight);
                } else if (n > 150) { clearInterval(t); notifyHeight(); }
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
              } else if (n > 150) {
                clearInterval(t);
                document.getElementById('content').textContent = raw;
                notifyHeight();
              }
            }, 20);
          } else {
            renderCore();
            runMathJax();
          }
        </script>
        </body></html>
        """

        let base = DiaryBodyWebAssets.baseDirectoryURL
        webView.loadHTMLString(html, baseURL: base)
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
        var lastIncludeMathJax: Bool?
        var lastCompact: CGFloat?

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
