/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

extension URLComponents {
    // Return the first query parameter that matches
    func valueForQuery(_ param: String) -> String? {
        return self.queryItems?.first { $0.name == param }?.value
    }
}

// The root navigation for the Router. Look at the tests to see a complete URL
enum NavigationPath {
    case url(webURL: URL?, isPrivate: Bool)
    case text(String)

    init?(url: URL) {
        let urlString = url.absoluteString
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
            let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            return nil
        }

        guard let scheme = components.scheme, urlSchemes.contains(scheme) else {
            return nil
        }

        if urlString.starts(with: "\(scheme)://open-url") {
            let url = components.valueForQuery("url")?.asURL
            // Unless the `open-url` URL specifies a `private` parameter,
            // use the last browsing mode the user was in.
            let isPrivate = Bool(components.valueForQuery("private") ?? "") ?? UserDefaults.standard.bool(forKey: "wasLastSessionPrivate")
            self = .url(webURL: url, isPrivate: isPrivate)
        } else if urlString.starts(with: "\(scheme)://open-text") {
            let text = components.valueForQuery("text")
            self = .text(text ?? "")
        } else if urlString.starts(with: "gemini://") {
            self = .url(webURL: url, isPrivate: false)
        } else {
            return nil
        }
    }

    static func handle(nav: NavigationPath, with bvc: BrowserViewController) {
        switch nav {
        case .url(let url, let isPrivate): NavigationPath.handleURL(url: url, isPrivate: isPrivate, with: bvc)
        case .text(let text): NavigationPath.handleText(text: text, with: bvc)
        }
    }

    private static func handleURL(url: URL?, isPrivate: Bool, with bvc: BrowserViewController) {
        if let newURL = url {
            bvc.switchToTabForURLOrOpen(newURL, isPrivate: isPrivate)
        } else {
            bvc.openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
        }
    }

    private static func handleText(text: String, with bvc: BrowserViewController) {
        bvc.openBlankNewTab(focusLocationField: false)
        bvc.urlBar(bvc.urlBar, didSubmitText: text)
    }
}

extension NavigationPath: Equatable {}

func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
    switch (lhs, rhs) {
    case let (.url(lhsURL, lhsPrivate), .url(rhsURL, rhsPrivate)):
        return lhsURL == rhsURL && lhsPrivate == rhsPrivate
    default:
        return false
    }
}
