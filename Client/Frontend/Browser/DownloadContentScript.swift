/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class DownloadContentScript: TabContentScript {
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "DownloadContentScript"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "downloadManager"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let browserViewController = tab?.browserViewController,
              let dictionary = message.body as? [String: Any?],
              let _url = dictionary["url"] as? String,
              let url = URL(string: _url),
              let mimeType = dictionary["mimeType"] as? String,
//              let size = dictionary["size"] as? Int64,
              let base64String = dictionary["base64String"] as? String,
              let data = Bytes.decodeBase64(base64String) else {
            return
        }

        // Note: url.lastPathComponent fails on blob: URLs (shrug).
        var filename = url.absoluteString.components(separatedBy: "/").last ?? "data"
        if filename.isEmpty {
            filename = "data"
        }

        if !filename.contains(".") {
            if let fileExtension = MIMEType.fileExtensionFromMIMEType(mimeType) {
                filename += ".\(fileExtension)"
            }
        }

        let path = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(filename)
        do {
            try data.write(to: path, options: .atomic)
        } catch {
            print("Failed to write")
        }

        let avc = UIActivityViewController(activityItems: [path], applicationActivities: nil)
        browserViewController.present(avc, animated: true, completion: nil)
    }
}
