/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

class CopiableLabel: UILabel {
    var copyText: String?

    func enableCopyMenu(with copyText: String?) {
        self.copyText = copyText
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(showCopyMenu(sender:))
        ))
    }

    @objc func showCopyMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    open override func copy(_ sender: Any?) {
        UIPasteboard.general.string = self.copyText
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    override public var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
}

extension PhotonActionSheetProtocol {
    @available(iOS 11.0, *)
    func getCertSubMenu(for tab: Tab) -> [[PhotonActionSheetItem]] {
        return menuActionsForCertificate(for: tab)
    }

    @available(iOS 11.0, *)
    private func menuActionsForCertificate(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let currentURL = tab.url else {
            return []
        }

        var fingerprintItem = PhotonActionSheetItem(title: "", accessory: .Text)
        fingerprintItem.customRender = { title, contentView in
            let fingerprint = GeminiClient.fingerprints[currentURL.domainURL.absoluteDisplayString] ?? "<unknown>"

            let l = CopiableLabel()
            l.numberOfLines = 0
            l.textAlignment = .center
            l.textColor = UIColor.theme.tableView.headerTextLight
            l.text = fingerprint
            l.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            l.accessibilityIdentifier = "cert.certificate-fingerprint"
            contentView.addSubview(l)
            l.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().inset(40)
            }
            l.enableCopyMenu(with: fingerprint.split(separator: "\n").joined(separator: ":"))
        }
        fingerprintItem.customHeight = { _ in
            return 180
        }

        return [[fingerprintItem]]
    }
//
//    @available(iOS 11.0, *)
//    private func menuActionsForWhitelistedSite(for tab: Tab) -> [[PhotonActionSheetItem]] {
//        guard let currentURL = tab.url else {
//            return []
//        }
//
//        let removeFromWhitelist = PhotonActionSheetItem(title: Strings.TPWhiteListRemove, iconString: "menu-TrackingProtection") { _, _ in
//            ContentBlocker.shared.whitelist(enable: false, url: currentURL) {
//                tab.reload()
//            }
//        }
//        return [[removeFromWhitelist]]
//    }
}

