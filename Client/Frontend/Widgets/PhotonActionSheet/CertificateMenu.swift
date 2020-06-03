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

func prettyFingerprint(_ s: [String]) -> String {
    return s.isEmpty ? "<none>" : s.enumerated().compactMap({
        if $0 > 0 {
            return ($0 % 8 == 0 ? "\n" : ":") + $1
        } else {
            return $1
        }
    }).joined().uppercased()
}

func oneLineFingerprint(_ s: [String]) -> String {
    return s.joined(separator: ":").uppercased()
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

        var clientTitle = PhotonActionSheetItem(title: "Client Certificate", accessory: .Text, bold: true)
        clientTitle.customRender = { label, _ in
            label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        }
        clientTitle.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight - 10
        }

        var clientFingerprintItem = PhotonActionSheetItem(title: "", accessory: .Text)
        clientFingerprintItem.customRender = { title, contentView in
            let clientFingerprint = [String]()

            let l = CopiableLabel()
            l.numberOfLines = clientFingerprint.isEmpty ? 1 : 4
            l.textAlignment = .center
            l.textColor = UIColor.theme.tableView.headerTextLight
            l.text = prettyFingerprint(clientFingerprint)
            l.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            l.accessibilityIdentifier = "cert.certificate-fingerprint"
            contentView.addSubview(l)
            l.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().inset(40)
            }
            if !clientFingerprint.isEmpty {
                l.enableCopyMenu(with: oneLineFingerprint(clientFingerprint))
            }
        }

        var serverTitle = PhotonActionSheetItem(title: "Server Certificate", accessory: .Text, bold: true)
        serverTitle.customRender = { label, _ in
            label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        }
        serverTitle.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight - 10
        }

        var serverFingerprintItem = PhotonActionSheetItem(title: "", accessory: .Text)
        serverFingerprintItem.customRender = { title, contentView in
            let serverFingerprint = GeminiClient.fingerprints[currentURL.domainURL.absoluteDisplayString] ?? []

            let l = CopiableLabel()
            l.numberOfLines = serverFingerprint.isEmpty ? 1 : 4
            l.textAlignment = .center
            l.textColor = UIColor.theme.tableView.headerTextLight
            l.text = prettyFingerprint(serverFingerprint)
            l.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            l.accessibilityIdentifier = "cert.certificate-fingerprint"
            contentView.addSubview(l)
            l.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().inset(40)
            }
            if !serverFingerprint.isEmpty {
                l.enableCopyMenu(with: oneLineFingerprint(serverFingerprint))
            }
        }
        serverFingerprintItem.customHeight = { _ in
            return 150
        }


        return [[clientTitle, clientFingerprintItem], [serverTitle, serverFingerprintItem]]
    }
}
