import WebKit
import Shared

private let log = Logger.browserLogger

enum GeminiClientStatus {
    case input(String)
    case success(String, String.Encoding)
    case redirect(String)
    case failure(String)
    case certificateRequired(String)
}

enum GeminiClientError: Error {
    case badURL
    case noResponder
    case responderUnableToHandle
    case badResponse(GeminiClientStatus)
}


class GeminiClient: NSObject {
    var inputStream: InputStream!
    var urlSchemeTask: WKURLSchemeTask
    var url: URL

    init(url: URL, urlSchemeTask: WKURLSchemeTask) {
        self.urlSchemeTask = urlSchemeTask
        self.url = url
    }

    func load() {
        DispatchQueue.global(qos: .userInitiated).async {
            self._load()
            RunLoop.current.run()
        }
    }

    fileprivate func _load() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, self.url.host! as CFString, UInt32(self.url.port ?? 1965), &readStream, &writeStream)

        inputStream = readStream!.takeRetainedValue()
        let outputStream: OutputStream = writeStream!.takeRetainedValue()

        inputStream.delegate = self

        inputStream.schedule(in: .current, forMode: .default)
        outputStream.schedule(in: .current, forMode: .default)
        // Enable SSL/TLS on the streams
        inputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
        outputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
        let sslSettings = [
            NSString(format: kCFStreamSSLValidatesCertificateChain): kCFBooleanFalse!,
            NSString(format: kCFStreamSSLIsServer): kCFBooleanFalse!
            ] as [NSString : Any]

        inputStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
        outputStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)

        inputStream.open()
        outputStream.open()

        let request = url.absoluteString + "\r\n"
        guard let data = request.data(using: .utf8) else {
            urlSchemeTask.didFailWithError(GeminiSchemeHandlerError.badURL)
            return
        }
        _ = data.withUnsafeBytes {
            outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
    }
}

extension GeminiClient: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            log.debug("OpenCompleted")
            break
        case .hasSpaceAvailable:
            log.debug("HasSpaceAvailable")
            break
        case .endEncountered:
            log.debug("EndEncountered")
            break
        case .hasBytesAvailable:
            log.debug("HasBytesAvailable")
            var data = Data()
            defer {
                inputStream.close()
            }
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            while inputStream.hasBytesAvailable {
                let read = inputStream.read(buffer, maxLength: bufferSize)
                if read < 0 {
                    urlSchemeTask.didFailWithError(self.inputStream.streamError!)
                    return
                } else if read == 0 {
                    //EOF
                    break
                }
                data.append(buffer, count: read)
            }
            log.debug("read \(data.count) bytes")
            parseResponse(data: data)
            break
        case .errorOccurred:
            urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
            break
        default:
            urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
            break
        }
    }

    // gemini://gemini.circumlunar.space/
    fileprivate func parseResponse(data: Data) {
        guard let ix = data.firstIndex(of: 13),
            data[ix+1] == 10,
            let header = String(data: data.prefix(upTo: ix), encoding: .utf8)
            else {
                urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                return
        }
        log.debug("header: \(header)")
        let status = parseStatus(header: header)
        switch status {
        case .success(let mime, let encoding):
            let data = data.dropFirst(ix+2)
            if mime.starts(with: "text/") {
                guard let body = String(data: data, encoding: encoding) else {
                    urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                    return
                }
                if mime == "text/gemini" {
                    guard let resp = parseBody(body).data(using: .utf8) else {
                        urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                        return
                    }
                    urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
                    urlSchemeTask.didReceive(resp)
                } else {
                    guard let resp = body.data(using: .utf8) else {
                        urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                        return
                    }
                    urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/plain", expectedContentLength: -1, textEncodingName: "utf-8"))
                    urlSchemeTask.didReceive(resp)
                }
            } else {
                urlSchemeTask.didReceive(URLResponse(url: url, mimeType: mime, expectedContentLength: -1,textEncodingName: nil))
                urlSchemeTask.didReceive(data)
            }
            urlSchemeTask.didFinish()
        case .redirect(let to):
            let body = "<meta http-equiv=\"refresh\" content=\"0; URL='\(to)'\" />"
            guard let data = body.data(using: .utf8) else {
                urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                return
            }
            urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        case .input(let question):
            let body = "<!DOCTYPE html><html lang=\"en\"><head><title>\(question)</title><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><body><h2>\(question)</h2><form><textarea id=q name=q></textarea><hr /><button>Submit</button></form><script>document.forms[0].onsubmit=function(e){e.preventDefault();document.location=document.location.origin+document.location.pathname+\"?\"+encodeURI(document.getElementById(\"q\").value)}</script>"
            guard let data = body.data(using: .utf8) else {
                urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
                return
            }
            urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        default:
            urlSchemeTask.didFailWithError(GeminiClientError.badResponse(status))
        }
    }

    fileprivate func parseStatus(header: String) -> GeminiClientStatus {
        switch header.prefix(1) {
        case "1": return .input(String(header.dropFirst(2)))
        case "2":
            do {
                let mimeRegex = try NSRegularExpression(pattern: #"^\d+\s+([^\s;]+)"#, options: [])
                let charsetRegex = try NSRegularExpression(pattern: #"charset\s*=\s*([^\s;]+)"#, options: [])
                let range = NSRange(header.startIndex..<header.endIndex, in: header)
                guard let m1 = mimeRegex.firstMatch(in: header, options: [], range: range),
                    let range1 = Range(m1.range(at: 1), in: header) else {
                        return .failure("cannot parse header")
                }
                let mime = String(header[range1])
                var charset = "utf-8"
                if let m2 = charsetRegex.firstMatch(in: header, options: [], range: range),
                    let range2 = Range(m2.range(at: 1), in: header) {
                    charset = String(header[range2])
                }
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
                let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                let encoding = String.Encoding(rawValue: nsEncoding)

                return .success(mime, encoding)
            } catch let err as NSError {
                return .failure("cannot parse header: \(err)")
            }
        case "3":
            do {
                let regex = try NSRegularExpression(pattern: #"^\d+\s+(\S.*)$"#, options: [])
                let range = NSRange(header.startIndex..<header.endIndex, in: header)
                guard let m = regex.firstMatch(in: header, options: [], range: range),
                    let range1 = Range(m.range(at: 1), in: header) else {
                        return .failure("cannot parse header")
                }
                let to = String(header[range1])
                return .redirect(to)
            } catch let err as NSError {
                return .failure("cannot parse header: \(err)")
            }
        case "4", "5": return .failure("failure!")
        case "6": return .failure("client certificate required!")
        default: return .failure("unknown response code!")
        }
    }

    fileprivate func parseBody(_ content: String) -> String {
        do {
            let h1Regex = try NSRegularExpression(pattern: #"^#\s+(.*)$"#, options: [])
            let h2Regex = try NSRegularExpression(pattern: #"^##\s+(.*)$"#, options: [])
            let h3Regex = try NSRegularExpression(pattern: #"^###\s+(.*)$"#, options: [])
            let listRegex = try NSRegularExpression(pattern: #"^\*\s+([^*]*)$"#, options: [])
            let linkRegex = try NSRegularExpression(pattern: #"^=>\s*(\S*)\s*(.*)?$"#, options: [])

            var pageTitle: String?
            var body = ""
            var pre = false
            for line in content.components(separatedBy: "\n") {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if line == "```" {
                    pre = !pre
                    if pre {
                        body.append("<pre><code>\n")
                    } else {
                        body.append("</code></pre>\n")
                    }
                    continue
                }
                if pre {
                    body.append("\(line)\n")
                }
                if let m = h1Regex.firstMatch(in: line, options: [], range: range),
                    let range = Range(m.range(at: 1), in: line) {
                    let title = line[range]
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h1>\(title)</h1>\n")
                } else if let m = h2Regex.firstMatch(in: line, options: [], range: range),
                    let range = Range(m.range(at: 1), in: line) {
                    let title = line[range]
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h2>\(title)</h2>\n")
                } else if let m = h3Regex.firstMatch(in: line, options: [], range: range),
                    let range = Range(m.range(at: 1), in: line) {
                    let title = line[range]
                    pageTitle = pageTitle ?? String(title)
                    body.append("<h3>\(title)</h3>\n")
                } else if let m = listRegex.firstMatch(in: line, options: [], range: range),
                    let range = Range(m.range(at: 1), in: line) {
                    let title = line[range]
                    body.append("<li>\(title)</li>\n")
                } else if let m = linkRegex.firstMatch(in: line, options: [], range: range),
                    let range1 = Range(m.range(at: 1), in: line),
                    let range2 = Range(m.range(at: 2), in: line) {
                    let link = line[range1]
                    let title = line[range2]
                    body.append("<div><a href=\"\(link)\">\(link)</a> \(title)</div>\n")
                } else {
                    body.append("<p>\(line)</p>\n")
                }
            }
            let title = pageTitle ?? self.url.absoluteDisplayString
            return "<!DOCTYPE html><html lang=\"en\"><head><title>\(title)</title><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><body>\n\(body)</body></html>"
        } catch let err as NSError {
            return "Error: \(err)"
        }
    }
}
