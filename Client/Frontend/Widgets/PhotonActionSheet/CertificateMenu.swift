/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import RealmSwift

public struct CertificatesTableViewDelegate {
    var dataSource: UITableViewDataSource & UITableViewDelegate
}

fileprivate var certificatesTableView: UITableView?

class CertificatesTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let data: Results<Certificate>
    let profile: Profile

    init(profile: Profile, host: String) {
        self.profile = profile
        self.data = profile.db.getAllCertificatesFor(host: host)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let cert = data[indexPath.row]
        let used = cert.lastUsedAt.toRelativeTimeString()
        let name = cert.name
        let activeStatus = cert.isActive ? "(active) " : ""
        cell.textLabel?.text = "\(activeStatus)\(name)"
        cell.detailTextLabel?.text = "last used \(used)"
        cell.backgroundColor = .clear
        cell.textLabel?.backgroundColor = .clear
        cell.detailTextLabel?.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.textColor = UIColor.theme.tableView.rowText
        cell.detailTextLabel?.textColor = UIColor.theme.tableView.rowDetailText
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteTitle = Strings.CertificatesPanelDeleteTitle
        let activateTitle = Strings.CertificatesPanelActivateTitle
        let deactivateTitle = Strings.CertificatesPanelDeactivateTitle
        let delete = UITableViewRowAction(style: .destructive, title: deleteTitle, handler: { (action, indexPath) in
            if let certificate = self.data[safe: indexPath.row] {
                _ = self.profile.db.deleteCertificate(certificate)
                certificatesTableView?.reloadData()
            }
        })
        var actions = [delete]
        if let certificate = data[safe: indexPath.row] {
            let title = certificate.isActive ? deactivateTitle : activateTitle
            let flipActive = UITableViewRowAction(style: .normal, title: title, handler: { (action, indexPath) in
                if let certificate = self.data[safe: indexPath.row] {
                    if certificate.isActive {
                        _ = self.profile.db.deactivateCertificatesFor(host: certificate.host)
                    } else {
                        _ = self.profile.db.activateCertificate(certificate)
                    }
                    certificatesTableView?.reloadData()
                }
            })
            flipActive.backgroundColor = UIColor.systemBlue
            actions.append(flipActive)
        }
        return actions
    }
}

fileprivate var certificatesTableViewDelegate: CertificatesTableViewDelegate?

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

        var clientLink = PhotonActionSheetItem(title: "Client certificates", accessory: .Disclosure) { action, _ in
            guard let host = tab.url?.host,
                let urlbar = (self as? BrowserViewController)?.urlBar,
                let bvc = self as? PresentableVC else { return }

            certificatesTableViewDelegate = CertificatesTableViewDelegate(dataSource: CertificatesTableDataSource(profile: self.profile, host: host))

            var list = PhotonActionSheetItem(title: "")
            list.customRender = { _, contentView in
                if certificatesTableView != nil {
                    certificatesTableView?.removeFromSuperview()
                }
                let tv = UITableView(frame: .zero, style: .plain)
                tv.dataSource = certificatesTableViewDelegate?.dataSource
                tv.delegate = certificatesTableViewDelegate?.dataSource
                tv.allowsSelection = false
                tv.backgroundColor = .clear
                tv.separatorStyle = .none

                contentView.addSubview(tv)
                tv.snp.makeConstraints { make in
                    make.edges.equalTo(contentView)
                }
                certificatesTableView = tv
            }

            list.customHeight = { _ in
                return PhotonActionSheetUX.RowHeight * 5
            }

            let back = PhotonActionSheetItem(title: Strings.BackTitle, iconString: "goBack") { _, _ in
                guard let urlbar = (self as? BrowserViewController)?.urlBar else { return }
                (self as? BrowserViewController)?.urlBarDidTapCert(urlbar)
            }

            let actions = UIDevice.current.userInterfaceIdiom == .pad ? [[back], [list]] : [[list], [back]]


            self.presentSheetWith(title: "Client Certificates", actions: actions, on: bvc, from: urlbar)
        }
        clientLink.customRender = { title, contentView in

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
            let serverFingerprint = GeminiClient.serverFingerprints[currentURL.domainURL.absoluteDisplayString] ?? []

            let l = CopiableLabel()
            l.numberOfLines = serverFingerprint.isEmpty ? 1 : 2
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
            return 60
        }


        return [[clientLink], [serverTitle, serverFingerprintItem]]
    }
}
