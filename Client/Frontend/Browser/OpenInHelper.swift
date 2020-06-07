/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MobileCoreServices
import PassKit
import WebKit
import QuickLook
import Shared

struct MIMEType {
    static let Bitmap = "image/bmp"
    static let CSS = "text/css"
    static let GIF = "image/gif"
    static let JavaScript = "text/javascript"
    static let JPEG = "image/jpeg"
    static let HTML = "text/html"
    static let OctetStream = "application/octet-stream"
    static let Passbook = "application/vnd.apple.pkpass"
    static let PDF = "application/pdf"
    static let PlainText = "text/plain"
    static let PNG = "image/png"
    static let WebP = "image/webp"
    static let Calendar = "text/calendar"
    static let USDZ = "model/usd"

    private static let webViewViewableTypes: [String] = [MIMEType.Bitmap, MIMEType.GIF, MIMEType.JPEG, MIMEType.HTML, MIMEType.PDF, MIMEType.PlainText, MIMEType.PNG, MIMEType.WebP]

    static func canShowInWebView(_ mimeType: String) -> Bool {
        return webViewViewableTypes.contains(mimeType.lowercased())
    }

    static func mimeTypeFromFileExtension(_ fileExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(), let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }

        return MIMEType.OctetStream
    }

    static func fileExtensionFromMIMEType(_ mimeType: String) -> String? {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue(), let fileExtension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue() {
            return fileExtension as String
        }
        return nil
    }
}

protocol OpenInHelper {
    init?(response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController)
    func open()
}

class OpenPassBookHelper: NSObject, OpenInHelper {
    fileprivate var url: URL

    fileprivate let browserViewController: BrowserViewController

    required init?(response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.Passbook, PKAddPassesViewController.canAddPasses(),
            let responseURL = response.url else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        super.init()
    }

    func open() {
        guard let passData = try? Data(contentsOf: url) else { return }

        do {
            let pass = try PKPass(data: passData)

            let passLibrary = PKPassLibrary()
            if passLibrary.containsPass(pass) {
                UIApplication.shared.open(pass.passURL!, options: [:])
            } else {
                if let addController = PKAddPassesViewController(pass: pass) {
                    browserViewController.present(addController, animated: true, completion: nil)
                }
            }
        } catch {
            let alertController = UIAlertController(title: Strings.UnableToAddPassErrorTitle, message: Strings.UnableToAddPassErrorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Strings.UnableToAddPassErrorDismiss, style: .cancel) { (action) in
                    // Do nothing.
            })
            browserViewController.present(alertController, animated: true, completion: nil)
            return
        }
    }
}

class OpenQLPreviewHelper: NSObject, OpenInHelper, QLPreviewControllerDataSource {
    var url: NSURL

    fileprivate let browserViewController: BrowserViewController

    fileprivate let previewController: QLPreviewController

    required init?(response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.USDZ, let responseURL = response.url as NSURL?, QLPreviewController.canPreview(responseURL), !canShowInWebView else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        self.previewController = QLPreviewController()
        super.init()
    }

    func open() {
        self.previewController.dataSource = self
        ensureMainThread {
            self.browserViewController.present(self.previewController, animated: true, completion: nil)
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.url
    }
}
