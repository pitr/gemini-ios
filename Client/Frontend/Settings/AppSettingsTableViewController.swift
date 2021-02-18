/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Title in the settings view controller title bar")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: .done,
            target: navigationController, action: #selector((navigationController as! ThemedNavigationController).done))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"

        // Refresh the user's FxA profile upon viewing settings. This will update their avatar,
        // display name, etc.
        ////profile.rustAccount.refreshProfile()
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            SearchSetting(settings: self),
            NewTabPageSetting(settings: self),
            OpenWithSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: "useInAppSafari", defaultValue: false,
                        titleText: Strings.SettingsUseInAppSafariTitle,
                        statusText: Strings.SettingsUseInAppSafariStatus),
           ]

        if #available(iOS 12.0, *) {
            generalSettings.append(SiriPageSetting(settings: self))
        }

        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.

        generalSettings += [
            BoolSetting(prefs: prefs, prefKey: "showClipboardBar", defaultValue: false,
                        titleText: Strings.SettingsOfferClipboardBarTitle,
                        statusText: Strings.SettingsOfferClipboardBarStatus),
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.ContextMenuShowLinkPreviews, defaultValue: true,
                        titleText: Strings.SettingsShowLinkPreviewsTitle,
                        statusText: Strings.SettingsShowLinkPreviewsStatus)
        ]

        settings += [ SettingSection(title: NSAttributedString(string: Strings.SettingsGeneralSectionTitle), children: generalSettings)]

        settings += [ SettingSection(title: NSAttributedString(string: "Gemini"), children: [
                                        InlineImagesSettings(settings: self)
        ])]

        settings += [ SettingSection(title: NSAttributedString(string: Strings.SettingsFeedbackTitle), children: [
            RateNonSetting(titleText: Strings.SettingsRateButton)
        ])]

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }

    class InlineImagesSettings: Setting {
        let profile: Profile

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let num = self.profile.prefs.intForKey(PrefsKeys.GeminiMaxImagesInline) ?? InlineImagesCountSettingsController.defaultImages
            return NSAttributedString(string: String(format: Strings.InlineImagesCount, num))
        }

        override var accessibilityIdentifier: String? { return "InlineImagesCount" }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            super.init(title: NSAttributedString(string: Strings.SettingsShowImagesInlineTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = InlineImagesCountSettingsController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

class InlineImagesCountSettingsController: SettingsTableViewController {
    let prefs: Prefs
    var numberOfInlinedImages: Int32
    static let defaultImages: Int32 = 5

    init(prefs: Prefs) {
        self.prefs = prefs
        numberOfInlinedImages = self.prefs.intForKey(PrefsKeys.GeminiMaxImagesInline) ?? InlineImagesCountSettingsController.defaultImages
        super.init(style: .grouped)
        self.title = Strings.SettingsShowImagesInlineTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {

        let createSetting: (Int32) -> CheckmarkSetting = { num in
            return CheckmarkSetting(title: NSAttributedString(string: "\(num)"), subtitle: nil, isChecked: { return num == self.numberOfInlinedImages }, onChecked: {
                self.numberOfInlinedImages = num
                self.prefs.setInt(Int32(num), forKey: PrefsKeys.GeminiMaxImagesInline)
                self.tableView.reloadData()
            })
        }

        let rows = [0, 1, 5, 10, 20, 30, 100].map(createSetting)
        let section = SettingSection(title: nil, footerTitle: NSAttributedString(string: Strings.SettingsShowImagesInlineStatus), children: rows)
        return [section]
    }
}
