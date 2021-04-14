import Shared
import Storage

extension BrowserViewController: CertificateHelperDelegate {
    func certificateRequested(host: String) {
        let createItem = PhotonActionSheetItem(title: Strings.CertificateHelperAlertCreate) { _, _ in
            var input: UITextField!
            let alert = UIAlertController(title: "Certificate Name", message: "Enter name you will be identified by on \(host)", preferredStyle:.alert)
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
                guard let name = input.text, let result = CertificateUtils.createCert(days: 365*100, name: name) else {
                    self.show(toast: ButtonToast(labelText: "Certificate creation failed", backgroundColor: UIColor.Photon.Grey60, textAlignment: .center))
                    return
                }
                _ = self.profile.db.addAndActivateCertificate(host: host, name: name, data: result.data, fingerprint: result.fingerprint).map {
                    self.tabManager.selectedTab?.reload()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addTextField { (textField) in
                input = textField
            }

            self.present(alert, animated: true)
        }
        var actions = [[createItem]]

        let useItems: [PhotonActionSheetItem] = profile.db.getAllCertificatesFor(host: host).map { (cert) -> PhotonActionSheetItem in
            return PhotonActionSheetItem(title: "Activate: \(cert.name)") { _, _ in
                if self.profile.db.activateCertificate(cert).isSuccess {
                    self.tabManager.selectedTab?.reload()
                } else {
                    self.show(toast: ButtonToast(labelText: "Could not activate \"\(cert.name)\"", backgroundColor: UIColor.Photon.Grey60, textAlignment: .center))
                }
            }
        }

        if useItems.count > 0 {
            actions.append(useItems)
        }
        presentSheetWith(actions: actions, on: self, from: urlBar)
    }
}
