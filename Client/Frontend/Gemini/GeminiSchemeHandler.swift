import WebKit
import Shared

private let log = Logger.browserLogger

enum GeminiSchemeHandlerError: Error {
    case badURL
}

class GeminiSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "gemini"

    var currentClient: GeminiClient?
    let profile: Profile

    init(profile: Profile) {
        self.profile = profile
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              url.host != nil else {
            urlSchemeTask.didFailWithError(GeminiSchemeHandlerError.badURL)
            return
        }

        if currentClient?.urlSchemeTask?.isEqual(urlSchemeTask) ?? false {
            // stop previous client if it's working on the same task
            currentClient?.stop()
        }

        let client = GeminiClient(url: url, urlSchemeTask: urlSchemeTask, profile: profile)
        currentClient = client
        client.load()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        log.info("webView(stop)")
        currentClient?.stop()
    }
}
