/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public enum KVOConstants: String {
    case loading = "loading"
    case estimatedProgress = "estimatedProgress"
    case URL = "URL"
    case title = "title"
    case canGoBack = "canGoBack"
    case canGoForward = "canGoForward"
    case contentSize = "contentSize"
}

public struct KeychainKey {
    public static let fxaPushRegistration = "account.push-registration"
    public static let apnsToken = "apnsToken"
}

public struct AppConstants {
    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil

    public static let scheme: String = {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return "unknown"
        }

        let scheme = identifier.replacingOccurrences(of: "com.pitr.ios.", with: "")
        return scheme
    }()

    /// The maximum length of a URL stored by Gemini.
    public static let DB_URL_LENGTH_MAX = 65536
}
