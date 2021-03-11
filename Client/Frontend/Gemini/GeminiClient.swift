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

    var urlSchemeTask: WKURLSchemeTask?
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
        self.urlSchemeTask = nil
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
            renderError(error: "Could not send request to \(url.absoluteString)")
            return
        }
        let conn = NWConnection(host: host, port: port, using: NWParameters(tls: opts))
        self.conn = conn
        conn.stateUpdateHandler  = { (state)  in
            switch state {
            case .failed(let err):
                self.renderError(error: err.localizedDescription)
                conn.cancel()
            case .waiting(let err):
                self.renderError(error: err.localizedDescription)
                conn.cancel()
            default:
                log.debug(state)
            }
        }
        conn.start(queue: GeminiClient.queue)
        conn.send(content: data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ (err) in
            if let err = err {
                log.debug(err)
            }
            conn.receiveMessage { (data, ctx, isComplete, err) in
                if let err = err {
                    log.debug(err)
                    return
                }
                if !isComplete {
                    log.error("not complete???")
                }
                conn.cancel()
                guard let data = data else {
                    self.renderError(error: "server responded with no content")
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
                renderError(error: "Invalid response")
                return
        }
        log.debug("header: \(firstLine)")
        guard let header = GeminiHeader(header: firstLine) else {
            renderError(error: "Invalid header: \(firstLine)")
            return
        }
        switch header {
        case .success(let mime):
            GeminiClient.redirects = 0
            let data = data.dropFirst(ix+2)
            if mime.contentType.starts(with: "text/") {
                guard let body = String(data: data, encoding: mime.charset) else {
                    renderError(error: "Could not parse body with encoding \(mime.charset)")
                    return
                }
                switch mime.contentType {
                case "text/gemini":
                    guard let resp = GeminiText.render(body, pageURL: self.url, profile: self.profile) else {
                        renderError(error: "Could not parse body")
                        return
                    }
                    render(resp, mime: "text/html")
                case "text/html":
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body")
                        return
                    }
                    render(resp, mime: "text/html")
                case "text/plain":
                    let result = GeminiText.getHeader(for: self.url, title: "", profile: self.profile) + "<pre><code>" + body
                    guard let data = result.data(using: .utf8) else {
                        renderError(error: "Could not parse body")
                        return
                    }
                    render(data, mime: "text/html")
                default:
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body")
                        return
                    }
                    render(resp, mime: "text/plain")
                }
            } else if MIMEType.canShowInWebView(mime.contentType) {
                render(data, mime: mime.contentType)
            } else {
                let body = "<script>webkit.messageHandlers.downloadManager.postMessage({url: \"\(self.url.absoluteString)\",mimeType: \"\(mime.contentType)\",size: \(data.count), base64String: \"\(data.base64EncodedString)\"})</script>"
                guard let data = body.data(using: .ascii) else {
                    renderError(error: "could not download file")
                    return
                }
                render(data, mime: "text/html")
            }
        case .redirect_permanent(let to), .redirect_temporary(let to):
            guard let url = URIFixup.getURL(to, relativeTo: self.url) else {
                renderError(error: "Could not find a way to redirect to \(to)")
                return
            }
            let body: String

            if url.host == self.url.host && url.port ?? 1965 == self.url.port ?? 1965 {
                body = "<meta http-equiv=\"refresh\" content=\"0; URL='\(to)'\" />"
            } else {
                body = GeminiText.getHeader(for: self.url, title: "Please confirm redirect", profile: self.profile) + "<h1>Please confirm redirect</h1><a href='\(url.absoluteString)'>\(url.absoluteString)</a>"
            }
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not redirect to \(to)")
                return
            }
            GeminiClient.redirects += 1
            if GeminiClient.redirects > 5 {
                renderError(error: "Too many redirects")
                return
            }
            render(data, mime: "text/html")
        case .input(let question), .sensitive_input(let question):
            GeminiClient.redirects = 0
            var body = GeminiText.getHeader(for: self.url, title: question, profile: self.profile)
            switch header {
            case .sensitive_input:
                body += "<h3>\(question)</h3><form><input autocapitalize=off type=password maxlength=1024 id=q name=q /><button>Submit</button><span id=s></span></form>"
            default:
                body += "<h3>\(question)</h3><form><textarea autofocus rows=10 maxlength=1024 required autocapitalize=off id=q name=q></textarea><button>Submit</button><span id=s></span></form>"
            }
            body += inputFooter
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render form to ask server's question: \(question)")
                return
            }
            render(data, mime: "text/html")
        case .slow_down(let wait):
            GeminiClient.redirects = 0
            renderError(error: "slow down: please wait at least \(wait) seconds before retrying")
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
            renderError(error: "\(header.description()): \(err)")
        case .client_certificate_required(let msg), .certificate_not_authorised(let msg), .certificate_not_valid(let msg):
            GeminiClient.redirects = 0
            var body = GeminiText.getHeader(for: self.url, title: msg, profile: self.profile)
            body += "<h1>\(header.description().capitalized)</h1><h3>\(msg)</h3>"
            body += "<div id='need-certificate'></div>"
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render server's certification message: \(msg)")
                return
            }
            render(data, mime: "text/html")
        }
    }

    fileprivate func render(_ data: Data, mime: String){
        self.urlSchemeTask?.didReceive(URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil))
        self.urlSchemeTask?.didReceive(data)
        self.urlSchemeTask?.didFinish()
        self.urlSchemeTask = nil
    }

    fileprivate func renderError(error: String) {
        GeminiClient.redirects = 0

        var body = GeminiText.getHeader(for: self.url, title: error, profile: self.profile)
        body += "<h2>\(error)</h2>"
        if let data = body.data(using: .utf8) {
            render(data, mime: "text/html")
        } else {
            render("browser error!".data(using: .utf8)!, mime: "text/html")
        }
    }
}
