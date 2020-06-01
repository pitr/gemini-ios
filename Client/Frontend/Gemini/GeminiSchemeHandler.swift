import WebKit
import Shared

private let log = Logger.browserLogger

enum GeminiSchemeHandlerError: Error {
    case badURL
}

class GeminiSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "gemini"

    var currentClient: GeminiClient?
    let prefs = NSUserDefaultsPrefs()

    override init() {
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(GeminiSchemeHandlerError.badURL)
            return
        }

        let client = GeminiClient(url: url, urlSchemeTask: urlSchemeTask, prefs: prefs)
        currentClient = client
        client.load()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        log.info("webView(stop)")
        do {
            currentClient?.stop()
        }
    }
}
