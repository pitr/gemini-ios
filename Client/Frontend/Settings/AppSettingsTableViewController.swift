/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.AppSettingsTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.AppSettingsDone,
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
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.EnableSiteTheme, defaultValue: false,
                        titleText: Strings.SettingsEnableSiteThemeTitle, statusText: Strings.SettingsEnableSiteThemeStatus),
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.EnableANSIEscapeCodes, defaultValue: false,
                        titleText: Strings.SettingsEnableAnsiCodeTitle, statusText: Strings.SettingsEnableAnsiCodeStatus),

        ])]

        settings += [ SettingSection(title: NSAttributedString(string: Strings.SettingsFeedbackTitle), children: [
            LinkNonSetting(titleText: Strings.SettingsFeedbackButton, url: "gemini://elaho.glv.one/feedback"),
            LinkNonSetting(titleText: Strings.SettingsRateButton, url: "https://itunes.apple.com/app/id1514950389?action=write-review")
        ])]

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }
}
