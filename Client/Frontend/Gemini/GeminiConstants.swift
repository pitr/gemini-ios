import Foundation

struct Mime {
    let contentType: String
    var charset: String.Encoding = .utf8
    var attributes: [String: String] = [:]
    init(meta: String) {
        let parts = meta.split(separator: ";").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        self.contentType = parts[0]
        for part in parts.dropFirst() {
            let chunks = part.split(separator: "=", maxSplits: 1).map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            if chunks.count != 2 { continue }
            let name = chunks[0]
            let value = chunks[1]
            if name == "charset" {
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(value as CFString)
                let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                self.charset = String.Encoding(rawValue: nsEncoding)
            } else {
                self.attributes[name] = value
            }
        }
    }
}

enum GeminiHeader {
    case input(question: String)
    case success(mime: Mime)
    case success_end_of_client_certificate_session(mime: Mime)
    case redirect_temporary(url: String)
    case redirect_permanent(url: String)
    case temporary_failure(err: String)
    case server_unavailable(err: String)
    case cgi_error(err: String)
    case proxy_error(err: String)
    case slow_down(wait: Int)
    case permanent_failure(err: String)
    case not_found(err: String)
    case gone(err: String)
    case proxy_request_refused(err: String)
    case bad_request(err: String)
    case client_certificate_required(msg: String)
    case transient_certificate_requested(msg: String)
    case authorised_certificate_required(msg: String)
    case certificate_not_accepted(msg: String)
    case future_certificate_rejected(msg: String)
    case expired_certificate_rejected(msg: String)

    init?(header: String) {
        let split = header.split(separator: " ", maxSplits: 1)
        guard let statusNumber = Int(split[0]) else { return nil }

        let meta = String(split[safe: 1] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        switch statusNumber {
        case 10:
            self = .input(question: meta)
        case 20:
            self = .success(mime: Mime(meta: meta))
        case 21:
            self = .success_end_of_client_certificate_session(mime: Mime(meta: meta))
        case 30:
            self = .redirect_temporary(url: meta)
        case 31:
            self = .redirect_permanent(url: meta)
        case 40:
            self = .temporary_failure(err: meta)
        case 41:
            self = .server_unavailable(err: meta)
        case 42:
            self = .cgi_error(err: meta)
        case 43:
            self = .proxy_error(err: meta)
        case 44:
            guard let wait = Int(meta) else { return nil }
            self = .slow_down(wait: wait)
        case 50:
            self = .permanent_failure(err: meta)
        case 51:
            self = .not_found(err: meta)
        case 52:
            self = .gone(err: meta)
        case 53:
            self = .proxy_request_refused(err: meta)
        case 59:
            self = .bad_request(err: meta)
        case 60:
            self = .client_certificate_required(msg: meta)
        case 61:
            self = .transient_certificate_requested(msg: meta)
        case 62:
            self = .authorised_certificate_required(msg: meta)
        case 63:
            self = .certificate_not_accepted(msg: meta)
        case 64:
            self = .future_certificate_rejected(msg: meta)
        case 65:
            self = .expired_certificate_rejected(msg: meta)
        default: return nil
        }
    }

    func description() -> String {
        switch self {
        case .input: return "INPUT"
        case .success: return "SUCCESS"
        case .success_end_of_client_certificate_session: return "SUCCESS - END OF CLIENT CERTIFICATE SESSION"
        case .redirect_temporary: return "REDIRECT - TEMPORARY"
        case .redirect_permanent: return "REDIRECT - PERMANENT"
        case .temporary_failure: return "TEMPORARY FAILURE"
        case .server_unavailable: return "SERVER UNAVAILABLE"
        case .cgi_error: return "CGI ERROR"
        case .proxy_error: return "PROXY ERROR"
        case .slow_down: return "SLOW DOWN"
        case .permanent_failure: return "PERMANENT FAILURE"
        case .not_found: return "NOT FOUND"
        case .gone: return "GONE"
        case .proxy_request_refused: return "PROXY REQUEST REFUSED"
        case .bad_request: return "BAD REQUEST"
        case .client_certificate_required: return "CLIENT CERTIFICATE REQUIRED"
        case .transient_certificate_requested: return "TRANSIENT CERTIFICATE REQUESTED"
        case .authorised_certificate_required: return "AUTHORISED CERTIFICATE REQUIRED"
        case .certificate_not_accepted: return "CERTIFICATE NOT ACCEPTED"
        case .future_certificate_rejected: return "FUTURE CERTIFICATE REJECTED"
        case .expired_certificate_rejected: return "EXPIRED CERTIFICATE REJECTED"
        }
    }
}

let inputFooter = """
<script>document.forms[0].onsubmit=function(e){e.preventDefault();document.location=document.location.origin+document.location.pathname+"?"+encodeURI(document.getElementById("q").value)}</script>
"""
