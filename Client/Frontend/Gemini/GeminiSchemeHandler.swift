import WebKit
import Shared

private let log = Logger.browserLogger

enum GeminiSchemeHandlerError: Error {
    case badURL
}

class GeminiSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "gemini"

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(GeminiSchemeHandlerError.badURL)
            return
        }

        GeminiClient(url: url, urlSchemeTask: urlSchemeTask).load()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
