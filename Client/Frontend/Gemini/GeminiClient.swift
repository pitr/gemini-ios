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

let htmlHeader = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
:root{--nc-font-sans:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,Cantarell,'Open Sans','Helvetica Neue',sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";--nc-font-mono:Consolas,monaco,'Ubuntu Mono','Liberation Mono','Courier New',Courier,monospace;--nc-tx-1:#000;--nc-tx-2:#1A1A1A;--nc-bg-1:#FFF;--nc-bg-2:#F6F8FA;--nc-bg-3:#E5E7EB;--nc-lk-1:#0070F3;--nc-lk-2:#0366D6;--nc-lk-tx:#FFF;--nc-ac-1:#79FFE1;--nc-ac-tx:#0C4047}@media (prefers-color-scheme: dark){:root{--nc-tx-1:#fff;--nc-tx-2:#eee;--nc-bg-1:#000;--nc-bg-2:#111;--nc-bg-3:#222;--nc-lk-1:#3291FF;--nc-lk-2:#0070F3;--nc-lk-tx:#FFF;--nc-ac-1:#7928CA;--nc-ac-tx:#FFF}}*{margin:0;padding:0}address,area,article,aside,audio,blockquote,datalist,details,dl,fieldset,figure,form,input,iframe,img,meter,nav,ol,optgroup,option,output,p,pre,progress,ruby,section,table,textarea,ul,video{margin-bottom:1rem}html,input,select,button{font-family:var(--nc-font-sans)}body{margin:0 auto;max-width:750px;padding:1rem;border-radius:6px;overflow-x:hidden;word-break:break-word;overflow-wrap:break-word;background:var(--nc-bg-1);color:var(--nc-tx-2);font-size:1.03rem;line-height:1.5}::selection{background:var(--nc-ac-1);color:var(--nc-ac-tx)}p{margin-bottom:1rem}h1,h2,h3,h4,h5,h6{line-height:1;color:var(--nc-tx-1);padding-top:.875rem}h1,h2,h3{color:var(--nc-tx-1);padding-bottom:2px;margin-bottom:8px;border-bottom:1px solid var(--nc-bg-2)}h4,h5,h6{margin-bottom:.3rem}h1{font-size:2.25rem}h2{font-size:1.85rem}h3{font-size:1.55rem}h4{font-size:1.25rem}h5{font-size:1rem}h6{font-size:.875rem}a{color:var(--nc-lk-1)}a:hover{color:var(--nc-lk-2)}abbr:hover{cursor:help}blockquote{padding:1.5rem;background:var(--nc-bg-2);border-left:5px solid var(--nc-bg-3)}abbr{cursor:help}blockquote :last-child{padding-bottom:0;margin-bottom:0}header{background:var(--nc-bg-2);border-bottom:1px solid var(--nc-bg-3);padding:2rem 1.5rem;margin:-2rem calc(0px - (50vw - 50%)) 2rem;padding-left:calc(50vw - 50%);padding-right:calc(50vw - 50%)}header h1,header h2,header h3{padding-bottom:0;border-bottom:0}header > :first-child{margin-top:0;padding-top:0}header > :last-child{margin-bottom:0}a button,button,input[type="submit"],input[type="reset"],input[type="button"]{font-size:1rem;display:inline-block;padding:6px 12px;text-align:center;text-decoration:none;white-space:nowrap;background:var(--nc-lk-1);color:var(--nc-lk-tx);border:0;border-radius:4px;box-sizing:border-box;cursor:pointer;color:var(--nc-lk-tx)}a button[disabled],button[disabled],input[type="submit"][disabled],input[type="reset"][disabled],input[type="button"][disabled]{cursor:default;opacity:.5;cursor:not-allowed}a button:focus,a button:hover,button:focus,button:hover,input[type="submit"]:focus,input[type="submit"]:hover,input[type="reset"]:focus,input[type="reset"]:hover,input[type="button"]:focus,input[type="button"]:hover{background:var(--nc-lk-2)}code,pre,kbd,samp{font-family:var(--nc-font-mono)}code,samp,kbd,pre{background:var(--nc-bg-2);border:1px solid var(--nc-bg-3);border-radius:4px;padding:3px 6px;font-size:.9rem}kbd{border-bottom:3px solid var(--nc-bg-3)}pre{padding:1rem 1.4rem;max-width:100%;overflow:auto}pre code{background:inherit;font-size:inherit;color:inherit;border:0;padding:0;margin:0}code pre{display:inline;background:inherit;font-size:inherit;color:inherit;border:0;padding:0;margin:0}details{padding:.6rem 1rem;background:var(--nc-bg-2);border:1px solid var(--nc-bg-3);border-radius:4px}summary{cursor:pointer;font-weight:700}details[open]{padding-bottom:.75rem}details[open] summary{margin-bottom:6px}details[open]>:last-child{margin-bottom:0}dt{font-weight:700}dd::before{content:'→ '}hr{border:0;border-bottom:1px solid var(--nc-bg-3);margin:1rem auto}fieldset{margin-top:1rem;padding:2rem;border:1px solid var(--nc-bg-3);border-radius:4px}legend{padding:auto .5rem}table{border-collapse:collapse;width:100%}td,th{border:1px solid var(--nc-bg-3);text-align:left;padding:.5rem}th{background:var(--nc-bg-2)}tr:nth-child(even){background:var(--nc-bg-2)}table caption{font-weight:700;margin-bottom:.5rem}textarea{max-width:100%}ol,ul{padding-left:2rem}li{margin-top:.4rem}ul ul,ol ul,ul ol,ol ol{margin-bottom:0}mark{padding:3px 6px;background:var(--nc-ac-1);color:var(--nc-ac-tx)}textarea,select,input{width:100%;padding:6px 12px;margin-bottom:.5rem;background:var(--nc-bg-2);color:var(--nc-tx-2);border:1px solid var(--nc-bg-2);border-radius:4px;box-shadow:none;box-sizing:border-box}textarea:focus,select:focus,input[type]:focus{border:1px solid var(--nc-bg-3);outline:0}img{max-width:100%}
</style>
"""
let htmlFooter = """
<script>document.forms[0].onsubmit=function(e){e.preventDefault();document.location=document.location.origin+document.location.pathname+"?"+encodeURI(document.getElementById("q").value)}</script>
"""

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
            renderError(error: "Could not send request to \(url.absoluteString)", for: url, to: urlSchemeTask)
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
                    if let error = inputStream.streamError {
                        renderError(error: error.localizedDescription, for: url, to: urlSchemeTask)
                    } else {
                        renderError(error: "Received error reading from server", for: url, to: urlSchemeTask)
                    }
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
            if let error = inputStream.streamError {
                renderError(error: error.localizedDescription, for: url, to: urlSchemeTask)
            } else {
                renderError(error: "Received error reading from server", for: url, to: urlSchemeTask)
            }
            break
        default:
            renderError(error: "Unknown error while reading from server", for: url, to: urlSchemeTask)
            break
        }
    }

    // gemini://gemini.circumlunar.space/
    fileprivate func parseResponse(data: Data) {
        guard let ix = data.firstIndex(of: 13),
            data[ix+1] == 10,
            let header = String(data: data.prefix(upTo: ix), encoding: .utf8)
            else {
                renderError(error: "Invalid response", for: url, to: urlSchemeTask)
                return
        }
        log.debug("header: \(header)")
        let status = parseStatus(header: header)
        switch status {
        case .success(let mime, let encoding):
            let data = data.dropFirst(ix+2)
            if mime.starts(with: "text/") {
                guard let body = String(data: data, encoding: encoding) else {
                    renderError(error: "Could not parse body with encoding \(encoding)", for: url, to: urlSchemeTask)
                    return
                }
                if mime == "text/gemini" {
                    guard let resp = parseBody(body).data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
                        return
                    }
                    urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
                    urlSchemeTask.didReceive(resp)
                } else {
                    guard let resp = body.data(using: .utf8) else {
                        renderError(error: "Could not parse body", for: url, to: urlSchemeTask)
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
                renderError(error: "Could not redirect to \(to)", for: url, to: urlSchemeTask)
                return
            }
            urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        case .input(let question):
            let body = htmlHeader+"<title>\(question)</title></head><body><h2>\(question)</h2><form><input autocapitalize=off id=q name=q /><hr /><button>Submit</button></form>"+htmlFooter
            guard let data = body.data(using: .utf8) else {
                renderError(error: "Could not render form tosk server's question: \(question)", for: url, to: urlSchemeTask)
                return
            }
            urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        case .certificateRequired(let msg):
            renderError(error: msg, for: url, to: urlSchemeTask)
        case .failure(let error):
            renderError(error: error, for: url, to: urlSchemeTask)
        }
    }

    fileprivate func renderError(error: String, for url: URL, to urlSchemeTask: WKURLSchemeTask) {
        let body = htmlHeader+"<title>\(error)</title></head><body><h2>\(error)</h2>"
        guard let data = body.data(using: .utf8) else {
            urlSchemeTask.didFailWithError(GeminiClientError.responderUnableToHandle)
            return
        }
        urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8"))
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
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
        case "4", "5": return .failure("error: \(header)")
        case "6": return .failure("client certificate required: \(header)")
        default: return .failure("unknown response code: \(header)")
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
                if line.contains("```") {
                    pre = !pre
                    if pre {
                        let l = line.replaceFirstOccurrence(of: "```", with: "<pre><code>")
                        body.append("\(l)\n")
                    } else {
                        let l = line.replaceFirstOccurrence(of: "```", with: "</code></pre>")
                        body.append("\(l)\n")
                    }
                    continue
                }
                if pre {
                    body.append("\(line)\n")
                    continue
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
                    let link = line[range1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let title = line[range2].trimmingCharacters(in: .whitespacesAndNewlines)
                    if link == title {
                        body.append("<p><a href=\"\(link)\">\(link)</a></p>\n")
                    } else {
                        body.append("<p><a href=\"\(link)\">\(link)</a> \(title)</p>\n")
                    }
                } else {
                    body.append("<p>\(line)</p>\n")
                }
            }
            let title = pageTitle ?? self.url.absoluteDisplayString
            let res = htmlHeader+"<title>\(title)</title></head><body>\n\(body)"
            log.debug(res)
            return res
        } catch let err as NSError {
            return "Error: \(err)"
        }
    }
}
