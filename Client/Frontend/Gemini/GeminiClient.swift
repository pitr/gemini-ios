import WebKit
import Shared
import Storage
import Network

private let log = Logger.browserLogger

extension SecCertificate {
    func fingerprint() -> [String] {
        guard let subject = SecCertificateCopySubjectSummary(self) else {
            log.debug("Certificate has no subject!")
            return []
        }
        log.debug("CN: \(subject)")
        let fingerprint = (SecCertificateCopyData(self) as Data).md5.hexEncodedStringArray
        let hex = fingerprint.joined(separator: ":")
        log.debug("Fingerprint: \(hex)")
        return fingerprint
    }
}

class GeminiClient: NSObject {
    static var serverFingerprints: [String: [String]] = [:]
    static let queue = DispatchQueue(label: "gemini", qos: .default)
    static var redirects = 0

    let urlSchemeTask: WKURLSchemeTask
    let url: URL
    var conn: NWConnection?
    let start: DispatchTime
    let profile: Profile

    init(url: URL, urlSchemeTask: WKURLSchemeTask, profile: Profile) {
        self.urlSchemeTask = urlSchemeTask
        if let fragment = url.fragment {
            self.url = URL(string: url.absoluteString.replacingOccurrences(of: "#\(fragment)", with: "")) ?? url
        } else {
            self.url = url
        }
        self.start = DispatchTime.now()
        self.profile = profile
    }

    func load() {
        var certificate = self.profile.db.getActiveCertificate(host: self.url.host!)
        if let c = certificate {
            let result = self.profile.db.recordVisit(for: c)
            if result.isFailure {
                certificate = nil
                log.error(result.failureValue!)
            }
        }
        self._load(cert: certificate?.data)
    }

    func stop() {
        self.conn?.cancel()
        self.conn = nil
    }

    fileprivate func _load(cert: Data?) {
        let host = NWEndpoint.Host(self.url.host!)
        let port = NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(self.url.port ?? 1965))
        let opts = NWProtocolTLS.Options()
        sec_protocol_options_set_tls_min_version(opts.securityProtocolOptions, .tlsProtocol12)
        if let data = cert,
           let id = CertificateUtils.toIdentity(data: data),
           let sec_identity = sec_identity_create(id) {
            sec_protocol_options_set_local_identity(opts.securityProtocolOptions, sec_identity)
        }
        sec_protocol_options_set_verify_block(opts.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
            sec_protocol_metadata_copy_peer_public_key(sec_protocol_metadata)
            let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
            self.readServerCert(trust: trust)
            sec_protocol_verify_complete(true)
        }, GeminiClient.queue)

        let request = url.absoluteString + "\r\n"
        guard let data = request.data(using: .utf8) else {
            renderError(error: "Could not send request to \(url.absoluteString)", for: url, to: urlSchemeTask)
            return
        }
        let conn = NWConnection(host: host, port: port, using: NWParameters(tls: opts))
        self.conn = conn
        conn.stateUpdateHandler  = { (state)  in
            switch state {
            case .failed(let err):
                self.renderError(error: err.localizedDescription, for: self.url, to: self.urlSchemeTask)
                conn.cancel()
            case .waiting(let err):
                self.renderError(error: err.localizedDescription, for: self.url, to: self.urlSchemeTask)
                conn.cancel()
            default:
                print(state)
            }
        }
        conn.start(queue: GeminiClient.queue)
        conn.send(content: data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ (err) in
            if let err = err {
                print(err)
            }
            conn.receiveMessage { (data, ctx, isComplete, err) in
                if let err = err {
                    print(err)
                    return
                }
                if !isComplete {
                    log.error("not complete???")
                }
                conn.cancel()
                guard let data = data else {
                    self.renderError(error: "server responded with no content", for: self.url, to: self.urlSchemeTask)
                    return
                }

                let endReceive = DispatchTime.now()
                var ms = (endReceive.uptimeNanoseconds - self.start.uptimeNanoseconds) / 1_000_000
                log.info("Received \(data.count) bytes in: \(ms)ms")
                self.parseResponse(data: data)
                ms = (DispatchTime.now().uptimeNanoseconds - endReceive.uptimeNanoseconds) / 1_000_000
                log.info("Parsed in: \(ms)ms")
            }
        }))
    }

    fileprivate func readServerCert(trust: SecTrust) {
        let num = SecTrustGetCertificateCount(trust)
        log.debug("Found \(num) certificates")

        for ix in 0..<num {
            guard let fingerprint = SecTrustGetCertificateAtIndex(trust, ix)?.fingerprint() else {
                continue
            }
            let hex = fingerprint.joined(separator: ":")
            log.debug("Fingerprint: \(hex)")
            if ix == 0 {
                GeminiClient.serverFingerprints[self.url.domainURL.absoluteDisplayString] = fingerprint
            }
        }
    }

    fileprivate func parseResponse(data: Data) {
        guard let ix = data.firstIndex(of: 13),
            data[ix+1] == 10,
            ix < (1024+3), // +3 for status code
            let firstLine = String(data: data.prefix(upTo: ix), encoding: .utf8) else {
                renderError(error: "Invalid response", for: url, to: urlSchemeTask)
                return
        }
        log.debug("header: \(firstLine)")
        guard let header = GeminiHeader(header: firstLine) else {
            renderError(error: "Invalid header: \(firstLine)", for: url, to: urlSchemeTask)
            return
        }
        switch header {
        case .success(let mime):
            GeminiClient.redirects = 0
            let data = data.dropFirst(ix+2)
            if mime.contentType.starts(with: "text/") {
                guard let body = String(data: data, encoding: mime.charset) else {
                    renderError(error: "Could not parse body with encoding \(mime.charset)", for: url, to: urlSchemeTask)
                    return
                }
                switch mime.contentType {
                case "text/gemini":
                    guard let resp = parseBody(body).data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(resp, mime: "text/html")
                case "text/html":
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(resp, mime: "text/html")
                case "text/plain":
                    let result = getHeader(for: self.url, title: "") + "<pre><code>" + body
                    guard let data = result.data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(data, mime: "text/html")
                default:
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(resp, mime: "text/plain")
                }
            } else {
                render(data, mime: mime.contentType)
            }
        case .redirect_permanent(let to), .redirect_temporary(let to):
            let body = "<meta http-equiv=\"refresh\" content=\"0; URL='\(to)'\" />"
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not redirect to \(to)", for: url, to: urlSchemeTask)
                return
            }
            GeminiClient.redirects += 1
            if GeminiClient.redirects > 5 {
                renderError(error: "Too many redirects", for: url, to: urlSchemeTask)
                return
            }
            render(data, mime: "text/html")
        case .input(let question), .sensitive_input(let question):
            GeminiClient.redirects = 0
            var body = getHeader(for: self.url, title: question)
            switch header {
            case .sensitive_input:
                body += "<h3>\(question)</h3><form><input autocapitalize=off type=password maxlength=1024 id=q name=q /><button>Submit</button><span id=s></span></form>"
            default:
                body += "<h3>\(question)</h3><form><textarea autofocus rows=10 maxlength=1024 required autocapitalize=off id=q name=q></textarea><button>Submit</button><span id=s></span></form>"
            }
            body += inputFooter
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render form to ask server's question: \(question)", for: url, to: urlSchemeTask)
                return
            }
            render(data, mime: "text/html")
        case .slow_down(let wait):
            GeminiClient.redirects = 0
            renderError(error: "slow down: please wait at least \(wait) seconds before retrying", for: url, to: urlSchemeTask)
        case .temporary_failure(let err),
             .server_unavailable(let err),
             .cgi_error(let err),
             .proxy_error(let err),
             .permanent_failure(let err),
             .not_found(let err),
             .gone(let err),
             .proxy_request_refused(let err),
             .bad_request(let err):
            GeminiClient.redirects = 0
            renderError(error: "\(header.description()): \(err)", for: url, to: urlSchemeTask)
        case .client_certificate_required(let msg), .certificate_not_authorised(let msg), .certificate_not_valid(let msg):
            GeminiClient.redirects = 0
            var body = getHeader(for: self.url, title: msg)
            body += "<h1>\(header.description().capitalized)</h1><h3>\(msg)</h3>"
            body += "<div id='need-certificate'></div>"
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render server's certification message: \(msg)", for: url, to: urlSchemeTask)
                return
            }
            render(data, mime: "text/html")
        }
    }

    fileprivate func render(_ data: Data, mime: String){
        urlSchemeTask.didReceive(URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil))
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    fileprivate func renderError(error: String, for url: URL, to urlSchemeTask: WKURLSchemeTask) {
        GeminiClient.redirects = 0

        var body = getHeader(for: self.url, title: error)
        body += "<h2>\(error)</h2>"
        if let data = body.data(using: .utf8) {
            render(data, mime: "text/html")
        } else {
            render("browser error!".data(using: .utf8)!, mime: "text/html")
        }
    }

    fileprivate func parseBody(_ content: String) -> String {
        do {
            let listRegex = try NSRegularExpression(pattern: #"^\*\s+(.+)$"#, options: [])
            let linkRegex = try NSRegularExpression(pattern: #"^=&gt;\s*(\S+)\s*(.*)$"#, options: [])

            var pageTitle: String?
            var body = ""
            var pre = false
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
                        body.append("</code></pre></figure>\n")
                    }
                    continue
                }
                if pre {
                    body.append("\(line)\n")
                } else if line.starts(with: "###") {
                    let title = line.dropFirst(3)
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h3>\(title)</h2>\n")
                } else if line.starts(with: "##") {
                    let title = line.dropFirst(2)
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h2>\(title)</h2>\n")
                } else if line.starts(with: "#") {
                    let title = line.dropFirst(1)
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h1>\(title)</h1>\n")
                } else if let m = listRegex.firstMatch(in: line, options: [], range: range),
                    let range = Range(m.range(at: 1), in: line) {
                    let title = line[range]
                    body.append("<li>\(title)</li>\n")
                } else if line.starts(with: "&gt;") {
                    let quote = line.dropFirst(4)
                    if quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        body.append("<blockquote><br/></blockquote>\n")
                    } else {
                        body.append("<blockquote>\(quote)</blockquote>\n")
                    }
                } else if let m = linkRegex.firstMatch(in: line, options: [], range: range),
                    let range1 = Range(m.range(at: 1), in: line),
                    let range2 = Range(m.range(at: 2), in: line) {
                    let link = line[range1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let title = line[range2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let url = URIFixup.getURL(link, relativeTo: self.url)
                    var prefix = "→"
                    if url?.scheme != "gemini" {
                        prefix = "⎋"
                    } else if url?.host != self.url.host {
                        prefix = "⇒"
                    } else if let img = url,
                              ["jpg", "jpeg", "gif ", "png"].contains(img.pathExtension.lowercased()) {
                        prefix = "🖼"
                        body.append("<p><a href=\"\(img.absoluteString)\" onclick=\"return inlineImage(this);\">\(prefix) \(title)</a></p>\n")
                        continue
                    }
                    if link == title {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(link)</a></p>\n")
                    } else if title.isEmptyOrWhitespace() {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(link)</a></p>\n")
                    } else {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(title)</a></p>\n")
                    }
                } else if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    body.append("<br/>\n")
                } else {
                    body.append("<p>\(line)</p>\n")
                }
            }
            let title = pageTitle ?? self.url.absoluteDisplayString

            return getHeader(for: self.url, title: title)+body
        } catch let err as NSError {
            return "Error: \(err)"
        }
    }

    fileprivate func getHeader(for url: URL, title: String) -> String {
        var header = try! String(contentsOfFile: Bundle.main.path(forResource: "GeminiHeader", ofType: "html")!)
        let theme = ThemeManager.instance.current.name
        let fontMono = getFontMono()
        header += "<style>@font-face{font-family:DejavuSansMono;src:url(data:font/ttf;base64,\(fontMono)) format(\"truetype\")}</style>"

        if self.profile.prefs.boolForKey(PrefsKeys.EnableSiteTheme) ?? false,
           let hash = url.host?.md5, hash.count > 2 {
            let hue = CGFloat(hash[0]) + CGFloat(hash[1]) / 510.0
            let saturation = CGFloat(hash[2]) / 255.0 / 2.0

            let bgNormal = UIColor(hue: hue, saturation: saturation/2.0, brightness: 0.95, alpha: 1.0).hexString
            let bgDark = UIColor(hue: hue, saturation: saturation, brightness: 0.2, alpha: 1.0).hexString

            header += "<style>.normal {background:\(bgNormal) !important} .dark {background:\(bgDark) !important}</style>"
        }

        return header+"<title>\(title)</title></head><body class=\(theme)>\n"
    }

    fileprivate func getFontMono() -> String {
        let path = Bundle.main.url(forResource: "DejaVuSansMonoNerdFontCompleteMonoWindowsCompatible", withExtension: "ttf64")!
        return try! String(contentsOf: path)
    }
}
