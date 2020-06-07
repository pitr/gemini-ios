/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

protocol CertificateHelperDelegate: AnyObject {
    func certificateRequested(host: String, transient: Bool)
}

class CertificateHelper: TabContentScript {
    weak var delegate: CertificateHelperDelegate?
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "Certificate"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "certificateHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let data = message.body as! [String: Bool]
        guard let host = tab?.url?.host else {
            // oops
            return
        }
        delegate?.certificateRequested(host: host, transient: data["transient"] ?? false)
    }
}
