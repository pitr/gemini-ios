/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class NewTabContentSettingsViewController: SettingsTableViewController {

    /* variables for checkmark settings */
    let prefs: Prefs
    var currentChoice: NewTabPage!
    var hasHomePage = false
    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)

        self.title = Strings.SettingsNewTabTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        self.currentChoice = NewTabAccessors.getNewTabPage(self.prefs)
        self.hasHomePage = NewTabAccessors.getHomePage(self.prefs) != nil

        let onFinished = {
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
            self.tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabTopSites), subtitle: nil, accessibilityIdentifier: "NewTabAsFirefoxHome", isChecked: {return self.currentChoice == NewTabPage.topSites}, onChecked: {
            self.currentChoice = NewTabPage.topSites
            onFinished()
        })
        let showBlankPage = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabBlankPage), subtitle: nil, accessibilityIdentifier: "NewTabAsBlankPage", isChecked: {return self.currentChoice == NewTabPage.blankPage}, onChecked: {
            self.currentChoice = NewTabPage.blankPage
            onFinished()
        })
        let showWebPage = WebPageSetting(prefs: prefs, prefKey: PrefsKeys.NewTabCustomUrlPrefKey, defaultValue: nil, placeholder: Strings.CustomNewPageURL, accessibilityIdentifier: "NewTabAsCustomURL", isChecked: {return !showTopSites.isChecked() && !showBlankPage.isChecked()}, settingDidChange: { (string) in
            self.currentChoice = NewTabPage.homePage
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
            self.tableView.reloadData()
        })
        showWebPage.textField.textAlignment = .natural

        let section = SettingSection(title: NSAttributedString(string: Strings.NewTabSectionName), footerTitle: NSAttributedString(string: Strings.NewTabSectionNameFooter), children: [showTopSites, showBlankPage, showWebPage])

        let topsitesSection = SettingSection(title: NSAttributedString(string: Strings.SettingsTopSitesCustomizeTitle), footerTitle: NSAttributedString(string: Strings.SettingsTopSitesCustomizeFooter), children: [TopSitesSettings(settings: self)])

        return [section, topsitesSection]
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }

    class TopSitesSettings: Setting {
        let profile: Profile

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let num = self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
            return NSAttributedString(string: String(format: Strings.TopSitesRowCount, num))
        }

        override var accessibilityIdentifier: String? { return "TopSitesRows" }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            super.init(title: NSAttributedString(string: Strings.ASTopSitesTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = TopSitesRowCountSettingsController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

class TopSitesRowCountSettingsController: SettingsTableViewController {
    let prefs: Prefs
    var numberOfRows: Int32
    static let defaultNumberOfRows: Int32 = 2

    init(prefs: Prefs) {
        self.prefs = prefs
        numberOfRows = self.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
        super.init(style: .grouped)
        self.title = Strings.AppMenuTopSitesTitleString
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {

        let createSetting: (Int32) -> CheckmarkSetting = { num in
            return CheckmarkSetting(title: NSAttributedString(string: "\(num)"), subtitle: nil, isChecked: { return num == self.numberOfRows }, onChecked: {
                self.numberOfRows = num
                self.prefs.setInt(Int32(num), forKey: PrefsKeys.NumberOfTopSiteRows)
                self.tableView.reloadData()
            })
        }

        let rows = [1, 2, 3, 4].map(createSetting)
        let section = SettingSection(title: NSAttributedString(string: Strings.TopSitesRowSettingFooter), footerTitle: nil, children: rows)
        return [section]
    }
}
