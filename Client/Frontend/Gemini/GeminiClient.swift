import WebKit
import Shared
import Storage

private let log = Logger.browserLogger

class GeminiClient: NSObject {
    static var serverFingerprints: [String: [String]] = [:]

    var inputStream: InputStream!
    var outputStream: OutputStream!
    var done = false
    let urlSchemeTask: WKURLSchemeTask
    let url: URL
    var data: Data
    let start: DispatchTime
    let profile: Profile

    init(url: URL, urlSchemeTask: WKURLSchemeTask, profile: Profile) {
        self.urlSchemeTask = urlSchemeTask
        if let fragment = url.fragment {
            self.url = URL(string: url.absoluteString.replacingOccurrences(of: "#\(fragment)", with: "")) ?? url
        } else {
            self.url = url
        }
        self.data = Data()
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
        let data = certificate?.data
        DispatchQueue.global(qos: .userInitiated).async {
            self._load(cert: data)
            RunLoop.current.run()
        }
    }

    fileprivate func _load(cert: Data?) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, self.url.host! as CFString, UInt32(self.url.port ?? 1965), &readStream, &writeStream)

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream.delegate = self

        inputStream.schedule(in: .current, forMode: .default)
        outputStream.schedule(in: .current, forMode: .default)

        // Enable SSL/TLS on the streams
        inputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
        outputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
        var sslSettings = [
            NSString(format: kCFStreamSSLValidatesCertificateChain): kCFBooleanFalse!,
            NSString(format: kCFStreamSSLIsServer): kCFBooleanFalse!,
            ] as [NSString : Any]

        if let data = cert, let p12 = CertificateUtils.toP12(data: data).successValue {
            sslSettings[NSString(format: kCFStreamSSLCertificates)] = p12 as CFArray
        }

        inputStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
        outputStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)

        inputStream.open()
        outputStream.open()

        let request = url.absoluteString + "\r\n"
        guard let data = request.data(using: .utf8) else {
            renderError(error: "Could not send request to \(url.absoluteString)", for: url, to: urlSchemeTask)
            return
        }
        _ = data.withUnsafeBytes {
            outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
    }

    func stop() {
        if !done {
            done = true
            inputStream.close()
            outputStream.close()
            self.inputStream = nil
            self.outputStream = nil
        }
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
}

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

extension GeminiClient: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if let trust = self.inputStream.property(forKey: kCFStreamPropertySSLPeerTrust as Stream.PropertyKey) as! SecTrust? {
                readServerCert(trust: trust)
            }

            break
        case .hasSpaceAvailable:
            log.error("HasSpaceAvailable")
            break
        case .endEncountered:
            let endReceive = DispatchTime.now()
            var ms = (endReceive.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            log.info("Received data in: \(ms)ms")
            parseResponse(data: data)
            ms = (DispatchTime.now().uptimeNanoseconds - endReceive.uptimeNanoseconds) / 1_000_000
            log.info("Parsed in: \(ms)ms")
            defer {
                done = true
                inputStream.close()
                outputStream.close()
                self.inputStream = nil
                self.outputStream = nil
            }
            break
        case .hasBytesAvailable:
            log.debug("hasBytesAvailable")
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            while inputStream.hasBytesAvailable {
                let read = inputStream.read(buffer, maxLength: bufferSize)
                if read < 0 {
                    log.error("HasBytesAvailable but error reading")
                    if let error = inputStream.streamError {
                        renderError(error: error.localizedDescription, for: url, to: urlSchemeTask)
                    } else {
                        renderError(error: "Received error reading from server", for: url, to: urlSchemeTask)
                    }
                    return
                } else if read == 0 {
                    break
                }
                data.append(buffer, count: read)
                log.debug("read \(read) bytes")
            }
            break
        case .errorOccurred:
            log.error("ErrorOccurred")
            if let error = inputStream.streamError {
                renderError(error: error.localizedDescription, for: url, to: urlSchemeTask)
            } else {
                renderError(error: "Received error reading from server", for: url, to: urlSchemeTask)
            }
            defer {
                done = true
                inputStream.close()
                outputStream.close()
                self.inputStream = nil
                self.outputStream = nil
            }
            break
        default:
            log.error("Unknown error while reading from server")
            renderError(error: "Unknown error while reading from server", for: url, to: urlSchemeTask)
            defer {
                done = true
                inputStream.close()
                outputStream.close()
                self.inputStream = nil
                self.outputStream = nil
            }
            break
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
            let data = data.dropFirst(ix+2)
            if mime.contentType.starts(with: "text/") {
                guard let body = String(data: data, encoding: mime.charset) else {
                    renderError(error: "Could not parse body with encoding \(mime.charset)", for: url, to: urlSchemeTask)
                    return
                }
                if mime.contentType == "text/gemini" {
                    guard let resp = parseBody(body).data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(with: resp, mime: "text/html")
                } else {
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    render(with: resp, mime: "text/plain")
                }
            } else {
                render(with: data, mime: mime.contentType)
            }
        case .redirect_permanent(let to), .redirect_temporary(let to):
            let body = "<meta http-equiv=\"refresh\" content=\"0; URL='\(to)'\" />"
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not redirect to \(to)", for: url, to: urlSchemeTask)
                return
            }
            render(with: data, mime: "text/html")
        case .input(let question), .sensitive_input(let question):
            var body = getHeader(for: self.url)
            var type: String
            switch header {
            case .sensitive_input:
                type = "password"
            default:
                type = "text"
            }
            body += "<title>\(question)</title></head><body><h3>\(question)</h3><form><input autocapitalize=off type=\(type) id=q name=q /><button>Submit</button></form>"+inputFooter
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render form to ask server's question: \(question)", for: url, to: urlSchemeTask)
                return
            }
            render(with: data, mime: "text/html")
        case .slow_down(let wait):
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
            renderError(error: "\(header.description()): \(err)", for: url, to: urlSchemeTask)
        case .client_certificate_required(let msg), .certificate_not_authorised(let msg), .certificate_not_valid(let msg):

            var body = getHeader(for: self.url)
            body += "<title>\(msg)</title></head><body><h1>\(header.description().capitalized)</h1><h3>\(msg)</h3>"
            body += "<div id='need-certificate'></div>"
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render server's certification message: \(msg)", for: url, to: urlSchemeTask)
                return
            }
            render(with: data, mime: "text/html")
        }
    }

    fileprivate func render(with data: Data, mime: String){
        urlSchemeTask.didReceive(URLResponse(url: url, mimeType: mime, expectedContentLength: -1, textEncodingName: "utf-8"))
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    fileprivate func renderError(error: String, for url: URL, to urlSchemeTask: WKURLSchemeTask) {
        var body = getHeader(for: self.url)
        body += "<title>\(error)</title></head><body><h2>\(error)</h2>"
        if let data = body.data(using: .utf8) {
            render(with: data, mime: "text/html")
        } else {
            render(with: "browser error!".data(using: .utf8)!, mime: "text/html")
        }
    }

    fileprivate func parseBody(_ content: String) -> String {
        do {
            let listRegex = try NSRegularExpression(pattern: #"^\*\s+(.+)$"#, options: [])
            let linkRegex = try NSRegularExpression(pattern: #"^=&gt;\s*(\S+)\s*(.*)$"#, options: [])

            var pageTitle: String?
            var body = ""
            var pre = false
            for rawLine in content.components(separatedBy: "\n") {
                let line = rawLine.escapeHTML()
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if line.starts(with: "```") {
                    pre = !pre
                    if pre {
                        body.append("<pre><code>")
                    } else {
                        body.append("</code></pre>\n")
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
                              ["jpg", "jpeg", "gif ", "png"].contains(img.pathExtension.lowercased()),
                              self.profile.prefs.boolForKey(PrefsKeys.GeminiShowImagesInline) ?? true {
                        body.append("<img src=\"\(img.absoluteString)\">\n")
                        continue
                    }
                    if link == title {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(link)</a></p>\n")
                    } else if title.isEmptyOrWhitespace() {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(link)</a></p>\n")
                    } else if self.profile.prefs.boolForKey(PrefsKeys.GeminiShowLinkURL) ?? false {
                        body.append("<p><a href=\"\(url?.absoluteString ?? link)\">\(prefix) \(link)</a> \(title)</p>\n")
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
            return getHeader(for: self.url)+"<title>\(title)</title></head><body>\n\(body)"
        } catch let err as NSError {
            return "Error: \(err)"
        }
    }

    fileprivate func getHeader(for url: URL) -> String {
        var header = try! String(contentsOfFile: Bundle.main.path(forResource: "GeminiHeader", ofType: "html")!)
        if !(self.profile.prefs.boolForKey(PrefsKeys.DisableSiteTheme) ?? false),
            let hash = url.host?.md5, hash.count > 2 {

            let hue = CGFloat(hash[0]) + CGFloat(hash[1]) / 510.0
            let saturation = CGFloat(hash[2]) / 255.0 / 2.0

            let bg1 = UIColor(hue: hue, saturation: saturation/2.0, brightness: 0.90, alpha: 1.0).hexString
            let bg2 = UIColor(hue: hue, saturation: saturation/4.0, brightness: 0.90, alpha: 1.0).hexString
            let dbg1 = UIColor(hue: hue, saturation: saturation, brightness: 0.20, alpha: 1.0).hexString
            let dbg2 = UIColor(hue: hue, saturation: saturation*2.0, brightness: 0.20, alpha: 1.0).hexString

            header += "<style>:root{--nc-bg-1:\(bg1);--nc-bg-2:\(bg2)}@media (prefers-color-scheme: dark){:root{--nc-bg-1:\(dbg1);--nc-bg-2:\(dbg2)}}</style>"
        }
        return header
    }
}
