import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let content: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = buildHTML(markdown: content)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML(markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let rendered = renderMarkdown(escaped)

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark ? "#1e1e1e" : "#ffffff"
        let textColor = isDark ? "#d4d4d4" : "#1d1d1f"
        let codeColor = isDark ? "#ce9178" : "#c7254e"
        let codeBg = isDark ? "#2d2d2d" : "#f5f5f5"
        let borderColor = isDark ? "#3a3a3a" : "#e0e0e0"
        let linkColor = isDark ? "#6cb6ff" : "#0066cc"
        let h1Color = isDark ? "#ffffff" : "#000000"
        let blockquoteBg = isDark ? "#252526" : "#f8f8f8"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
            font-size: 14px;
            line-height: 1.7;
            color: \(textColor);
            background: \(bgColor);
            padding: 20px 24px;
            word-wrap: break-word;
        }
        h1, h2, h3, h4, h5, h6 {
            color: \(h1Color);
            margin-top: 20px;
            margin-bottom: 8px;
            line-height: 1.3;
        }
        h1 { font-size: 22px; font-weight: 700; border-bottom: 2px solid \(borderColor); padding-bottom: 6px; }
        h2 { font-size: 18px; font-weight: 600; border-bottom: 1px solid \(borderColor); padding-bottom: 4px; }
        h3 { font-size: 15px; font-weight: 600; }
        h4, h5, h6 { font-size: 14px; font-weight: 600; }
        p { margin-bottom: 12px; }
        a { color: \(linkColor); text-decoration: none; }
        a:hover { text-decoration: underline; }
        code {
            font-family: 'SF Mono', 'Menlo', 'Monaco', monospace;
            font-size: 12px;
            color: \(codeColor);
            background: \(codeBg);
            padding: 1px 5px;
            border-radius: 4px;
        }
        pre {
            background: \(codeBg);
            border: 1px solid \(borderColor);
            border-radius: 6px;
            padding: 14px 16px;
            overflow-x: auto;
            margin-bottom: 14px;
        }
        pre code {
            color: \(textColor);
            background: none;
            padding: 0;
            font-size: 12.5px;
            line-height: 1.6;
        }
        blockquote {
            border-left: 3px solid \(borderColor);
            margin-left: 0;
            padding: 8px 16px;
            background: \(blockquoteBg);
            border-radius: 0 4px 4px 0;
            margin-bottom: 12px;
            color: \(isDark ? "#9e9e9e" : "#555");
        }
        ul, ol { padding-left: 24px; margin-bottom: 12px; }
        li { margin-bottom: 4px; }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 14px;
            font-size: 13px;
        }
        th, td {
            border: 1px solid \(borderColor);
            padding: 7px 12px;
            text-align: left;
        }
        th {
            background: \(codeBg);
            font-weight: 600;
        }
        tr:nth-child(even) td {
            background: \(isDark ? "#252526" : "#fafafa");
        }
        hr {
            border: none;
            border-top: 1px solid \(borderColor);
            margin: 20px 0;
        }
        .task-checkbox { margin-right: 6px; }
        strong { font-weight: 600; }
        em { font-style: italic; }
        del { text-decoration: line-through; opacity: 0.7; }
        </style>
        </head>
        <body>\(rendered)</body>
        </html>
        """
    }

    // MARK: - Minimal Markdown → HTML renderer

    private func renderMarkdown(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var output = ""
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                let codeContent = codeLines.joined(separator: "\n")
                output += "<pre><code\(lang.isEmpty ? "" : " class=\"language-\(lang)\"")>\(codeContent)</code></pre>\n"
                i += 1
                continue
            }

            // Headings
            if line.hasPrefix("######") {
                output += "<h6>\(applyInline(String(line.dropFirst(6)).trimmed))</h6>\n"
            } else if line.hasPrefix("#####") {
                output += "<h5>\(applyInline(String(line.dropFirst(5)).trimmed))</h5>\n"
            } else if line.hasPrefix("####") {
                output += "<h4>\(applyInline(String(line.dropFirst(4)).trimmed))</h4>\n"
            } else if line.hasPrefix("###") {
                output += "<h3>\(applyInline(String(line.dropFirst(3)).trimmed))</h3>\n"
            } else if line.hasPrefix("##") {
                output += "<h2>\(applyInline(String(line.dropFirst(2)).trimmed))</h2>\n"
            } else if line.hasPrefix("#") {
                output += "<h1>\(applyInline(String(line.dropFirst(1)).trimmed))</h1>\n"
            }
            // Blockquote
            else if line.hasPrefix("&gt;") {
                output += "<blockquote><p>\(applyInline(String(line.dropFirst(4)).trimmed))</p></blockquote>\n"
            }
            // HR
            else if line == "---" || line == "***" || line == "___" {
                output += "<hr>\n"
            }
            // Table
            else if line.contains("|") && (i + 1 < lines.count && lines[i + 1].contains("---")) {
                let headers = parseTableRow(line)
                i += 2 // skip separator row
                var tableHTML = "<table><thead><tr>"
                for h in headers { tableHTML += "<th>\(applyInline(h))</th>" }
                tableHTML += "</tr></thead><tbody>"
                while i < lines.count && lines[i].contains("|") {
                    let cells = parseTableRow(lines[i])
                    tableHTML += "<tr>"
                    for c in cells { tableHTML += "<td>\(applyInline(c))</td>" }
                    tableHTML += "</tr>"
                    i += 1
                }
                tableHTML += "</tbody></table>\n"
                output += tableHTML
                continue
            }
            // Unordered list
            else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                var listItems = ""
                while i < lines.count, let suffix = listPrefix(lines[i]) {
                    // Task list
                    if suffix.hasPrefix("[ ] ") {
                        listItems += "<li><input type=\"checkbox\" class=\"task-checkbox\" disabled>\(applyInline(String(suffix.dropFirst(4))))</li>\n"
                    } else if suffix.hasPrefix("[x] ") || suffix.hasPrefix("[X] ") {
                        listItems += "<li><input type=\"checkbox\" class=\"task-checkbox\" checked disabled>\(applyInline(String(suffix.dropFirst(4))))</li>\n"
                    } else {
                        listItems += "<li>\(applyInline(suffix))</li>\n"
                    }
                    i += 1
                }
                output += "<ul>\n\(listItems)</ul>\n"
                continue
            }
            // Ordered list
            else if orderedListPrefix(line) != nil {
                var listItems = ""
                while i < lines.count, let suffix = orderedListPrefix(lines[i]) {
                    listItems += "<li>\(applyInline(suffix))</li>\n"
                    i += 1
                }
                output += "<ol>\n\(listItems)</ol>\n"
                continue
            }
            // Blank line
            else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                output += "\n"
            }
            // Paragraph
            else {
                output += "<p>\(applyInline(line))</p>\n"
            }

            i += 1
        }

        return output
    }

    private func applyInline(_ text: String) -> String {
        var s = text

        // Bold + italic
        s = applyRegex(s, pattern: "\\*\\*\\*(.+?)\\*\\*\\*", template: "<strong><em>$1</em></strong>")
        // Bold
        s = applyRegex(s, pattern: "\\*\\*(.+?)\\*\\*", template: "<strong>$1</strong>")
        s = applyRegex(s, pattern: "__(.+?)__", template: "<strong>$1</strong>")
        // Italic
        s = applyRegex(s, pattern: "\\*(.+?)\\*", template: "<em>$1</em>")
        s = applyRegex(s, pattern: "_(.+?)_", template: "<em>$1</em>")
        // Strikethrough
        s = applyRegex(s, pattern: "~~(.+?)~~", template: "<del>$1</del>")
        // Inline code (already HTML-escaped)
        s = applyRegex(s, pattern: "`([^`]+)`", template: "<code>$1</code>")
        // Links
        s = applyRegex(s, pattern: "\\[(.+?)\\]\\((.+?)\\)", template: "<a href=\"$2\">$1</a>")
        // Images
        s = applyRegex(s, pattern: "!\\[(.+?)\\]\\((.+?)\\)", template: "<img src=\"$2\" alt=\"$1\">")

        return s
    }

    private func applyRegex(_ input: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }

    private func listPrefix(_ line: String) -> String? {
        if line.hasPrefix("- ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("* ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("+ ") { return String(line.dropFirst(2)) }
        return nil
    }

    private func orderedListPrefix(_ line: String) -> String? {
        if let dotRange = line.range(of: ". "),
           line[line.startIndex..<dotRange.lowerBound].allSatisfy({ $0.isNumber }) {
            return String(line[dotRange.upperBound...])
        }
        return nil
    }

    private func parseTableRow(_ line: String) -> [String] {
        let parts = line.components(separatedBy: "|")
        return parts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }
}
