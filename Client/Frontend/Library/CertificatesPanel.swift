/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private struct CertificatesPanelUX {
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemWidth = 170
    static let HeaderHeight: CGFloat = 28
}

class CertificatesPanel: UIViewController, UITableViewDelegate, UITableViewDataSource, LibraryPanel, UIDocumentInteractionControllerDelegate {
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    let profile: Profile
    var tableView = UITableView()

    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    private var certificates: [[Certificate]]

    // MARK: - Lifecycle
    init(profile: Profile) {
        self.profile = profile
        self.certificates = profile.db.getAllCertificatesByHost()
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: .DynamicFontChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TwoLineTableViewCell.self, forCellReuseIdentifier: "TwoLineTableViewCell")
        tableView.register(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: "SiteTableViewHeader")
        tableView.layoutMargins = .zero
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "CertificatesTable"
        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    @objc func notificationReceived(_ notification: Notification) {
        DispatchQueue.main.async {
            self.reloadData()

            switch notification.name {
            case .DynamicFontChanged:
                if self.emptyStateOverlayView.superview != nil {
                    self.emptyStateOverlayView.removeFromSuperview()
                }
                self.emptyStateOverlayView = self.createEmptyStateOverlayView()
                break
            default:
                // no need to do anything at all
                print("Error: Received unexpected notification \(notification.name)")
                break
            }
        }
    }

    func reloadData() {
        self.certificates = self.profile.db.getAllCertificatesByHost()
        tableView.reloadData()
        updateEmptyPanelState()
    }

    // MARK: - Empty State
    private func updateEmptyPanelState() {
        if certificates.isEmpty {
            if emptyStateOverlayView.superview == nil {
                view.addSubview(emptyStateOverlayView)
                view.bringSubviewToFront(emptyStateOverlayView)
                emptyStateOverlayView.snp.makeConstraints { make in
                    make.edges.equalTo(self.tableView)
                }
            }
        } else {
            emptyStateOverlayView.removeFromSuperview()
        }
    }

    fileprivate func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.theme.homePanel.panelBackground

        let logoImageView = UIImageView(image: UIImage.templateImageNamed("emptyCertificates"))
        logoImageView.tintColor = UIColor.Photon.Grey60
        overlayView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.size.equalTo(60)
            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(LibraryPanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = Strings.CertificatesPanelEmptyStateTitle
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = UIColor.theme.homePanel.welcomeScreenText
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp.bottom).offset(CertificatesPanelUX.WelcomeScreenPadding)
            make.width.equalTo(CertificatesPanelUX.WelcomeScreenItemWidth)
        }

        return overlayView
    }

    // MARK: - TableView Delegate / DataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineTableViewCell", for: indexPath) as! TwoLineTableViewCell

        return configureCertificateCell(cell, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.theme.tableView.headerTextDark
            header.contentView.backgroundColor = UIColor.theme.tableView.headerBackground
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard certificates[safe: section]?.count ?? 0 > 0 else { return 0 }

        return CertificatesPanelUX.HeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let certs = certificates[safe: section], certs.count > 0 else { return nil }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SiteTableViewHeader") as? SiteTableViewHeader

        header?.textLabel?.text = certs[0].host
        header?.showBorder(for: .top, section != 0)

        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func configureCertificateCell(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        if let certs = certificates[safe: indexPath.section],
            let certificate = certs[safe: indexPath.row],
            let cell = cell as? TwoLineTableViewCell {
            let activeStatus = certificate.isActive ? "(active) " : ""
            let used = certificate.lastUsedAt.toRelativeTimeString()
            cell.setLines(activeStatus+certificate.name, detailText: "last used \(used)")

            if let url = "gemini://\(certificate.host)/".asURL {
                cell.imageView?.image = FaviconFetcher.letter(forUrl: url)
                if certificate.isActive {
                    cell.imageView?.image = cell.imageView?.image
                }
            } else {
                cell.imageView?.image = FaviconFetcher.defaultFavicon
            }
            cell.imageView?.contentMode = .scaleAspectFill
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return certificates.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificates[safe: section]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteTitle = Strings.CertificatesPanelDeleteTitle
        let activateTitle = Strings.CertificatesPanelActivateTitle
        let deactivateTitle = Strings.CertificatesPanelDeactivateTitle
        let delete = UITableViewRowAction(style: .destructive, title: deleteTitle, handler: { (action, indexPath) in
            if let certs = self.certificates[safe: indexPath.section],
                let certificate = certs[safe: indexPath.row] {
                _ = self.profile.db.deleteCertificate(certificate)
                self.reloadData()
            }
        })
        var actions = [delete]
        if let certs = certificates[safe: indexPath.section],
            let certificate = certs[safe: indexPath.row] {
            let title = certificate.isActive ? deactivateTitle : activateTitle
            let flipActive = UITableViewRowAction(style: .normal, title: title, handler: { (action, indexPath) in
                if let certs = self.certificates[safe: indexPath.section],
                    let certificate = certs[safe: indexPath.row] {
                    if certificate.isActive {
                        _ = self.profile.db.deactivateCertificatesFor(host: certificate.host)
                        self.reloadData()
                    } else {
                        _ = self.profile.db.activateCertificate(certificate)
                        self.reloadData()
                    }
                }
            })
            flipActive.backgroundColor = view.tintColor
            actions.append(flipActive)
        }
        return actions
    }
    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension CertificatesPanel: Themeable {
    func applyTheme() {
        emptyStateOverlayView.removeFromSuperview()
        emptyStateOverlayView = createEmptyStateOverlayView()
        updateEmptyPanelState()

        tableView.backgroundColor = UIColor.theme.tableView.rowBackground
        tableView.separatorColor = UIColor.theme.tableView.separator

        reloadData()
    }
}
