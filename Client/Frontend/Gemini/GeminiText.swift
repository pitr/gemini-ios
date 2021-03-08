import Shared

class GeminiText {
    static func render(_ content: String, pageURL: URL, profile: Profile) -> Data? {
        do {
            let listRegex = try NSRegularExpression(pattern: #"^\*\s+(.+)$"#, options: [])
            let linkRegex = try NSRegularExpression(pattern: #"^=&gt;\s*(\S+)\s*(.*)$"#, options: [])

            var pageTitle: String?
            var body = ""
            var pre = false
            var ansi = Ansi()
            var precounter = 0
            for rawLine in content.components(separatedBy: "\n") {
                let line = rawLine.escapeHTML()
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if line.starts(with: "```") {
                    pre = !pre
                    if pre {
                        var title = rawLine.replaceFirstOccurrence(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines).escapeHTML()
                        if title.isEmpty {
                            title = "unlabelled preformatted text"
                        }
                        precounter += 1
                        body.append("<figure role='img' aria-labelledby='pre-\(precounter)'><figcaption id='pre-\(precounter)'>\(title)</figcaption><pre><code>")
                    } else {
                        body.append(ansi.reset())
                        body.append("</code></pre></figure>\n")
                    }
                    continue
                }
                if pre {
                    body.append(ansi.parse(line))
                    body.append("\n")
                } else if line.starts(with: "###") {
                    let title = String(line.dropFirst(3))
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h3>\(ansi.parse(title))\(ansi.reset())</h3>\n")
                } else if line.starts(with: "##") {
                    let title = String(line.dropFirst(2))
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h2>\(ansi.parse(title))\(ansi.reset())</h2>\n")
                } else if line.starts(with: "#") {
                    let title = String(line.dropFirst(1))
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h1>\(ansi.parse(title))\(ansi.reset())</h1>\n")
                } else if let m = listRegex.firstMatch(in: line, options: [], range: range),
                          let range = Range(m.range(at: 1), in: line) {
                    let title = String(line[range])
                    body.append("<li>\(ansi.parse(title))\(ansi.reset())</li>\n")
                } else if line.starts(with: "&gt;") {
                    let quote = String(line.dropFirst(4))
                    if quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        body.append("<blockquote><br/></blockquote>\n")
                    } else {
                        body.append("<blockquote>\(ansi.parse(quote))\(ansi.reset())</blockquote>\n")
                    }
                } else if let m = linkRegex.firstMatch(in: line, options: [], range: range),
                          let range1 = Range(m.range(at: 1), in: line),
                          let range2 = Range(m.range(at: 2), in: line) {
                    let link = line[range1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let title = line[range2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let url = URIFixup.getURL(link, relativeTo: pageURL)
                    var clazz = "samedomain"
                    if url?.scheme != "gemini" {
                        clazz = "external"
                    } else if url?.host != pageURL.host {
                        clazz = "diffdomain"
                    } else if let img = url,
                              ["jpg", "jpeg", "gif ", "png"].contains(img.pathExtension.lowercased()) {
                        clazz = "image"
                        body.append("<p><a href=\"\(img.absoluteString)\" onclick=\"return inlineImage(this);\" class=\(clazz)>\(title)</a></p>\n")
                        continue
                    }
                    if link == title || title.isEmptyOrWhitespace() {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\" class=\(clazz)>\(link)</a></p>\n")
                    } else {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\" class=\(clazz)>\(ansi.parse(title))\(ansi.reset())</a></p>\n")
                    }
                } else if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    body.append("<br/>\n")
                } else {
                    body.append("<p>\(ansi.parse(line))\(ansi.reset())</p>\n")
                }
            }
            let title = pageTitle ?? pageURL.absoluteDisplayString

            let page = getHeader(for: pageURL, title: title, profile: profile)+body
            return page.data(using: .utf8)
        } catch let err as NSError {
            return "Error: \(err)".data(using: .utf8)
        }
    }

    static func getHeader(for url: URL, title: String, profile: Profile) -> String {
        var header = try! String(contentsOfFile: Bundle.main.path(forResource: "GeminiHeader", ofType: "html")!)
        let theme = ThemeManager.instance.current.name
        let fontMono = getFontMono()
        header += "<style>@font-face{font-family:DejavuSansMono;src:url(data:font/ttf;base64,\(fontMono)) format(\"truetype\")}</style>"

        if profile.prefs.boolForKey(PrefsKeys.EnableSiteTheme) ?? false,
           let hash = url.host?.md5, hash.count > 2 {
            let hue = CGFloat(hash[0]) + CGFloat(hash[1]) / 510.0
            let saturation = CGFloat(hash[2]) / 255.0 / 2.0

            let bgNormal = UIColor(hue: hue, saturation: saturation/2.0, brightness: 0.95, alpha: 1.0).hexString
            let bgDark = UIColor(hue: hue, saturation: saturation, brightness: 0.2, alpha: 1.0).hexString

            header += "<style>.normal {background:\(bgNormal) !important} .dark,.dark input,.dark textarea {background:\(bgDark) !important}</style>"
        }

        return header+"<title>\(title)</title></head><body class=\(theme)>\n"
    }

    fileprivate static func getFontMono() -> String {
        let path = Bundle.main.url(forResource: "DejaVuSansMonoNerdFontCompleteMonoWindowsCompatible", withExtension: "ttf64")!
        return try! String(contentsOf: path)
    }
}
