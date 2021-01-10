/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

import Shared
import XCGLogger

enum ShortcutType: String {
    case newTab = "NewTab"
    case openLastBookmark = "OpenLastBookmark"

    init?(fullType: String) {
        guard let last = fullType.components(separatedBy: ".").last else { return nil }

        self.init(rawValue: last)
    }

    var type: String {
        return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
    }
}

class QuickActions: NSObject {

    fileprivate let log = Logger.browserLogger

    static let QuickActionsVersion = "1.0"
    static let QuickActionsVersionKey = "dynamicQuickActionsVersion"

    static let TabURLKey = "url"
    static let TabTitleKey = "title"

    fileprivate let lastBookmarkTitle = NSLocalizedString("Open Last Bookmark", tableName: "3DTouchActions", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")

    static var sharedInstance = QuickActions()

    var launchedShortcutItem: UIApplicationShortcutItem?

    // MARK: Administering Quick Actions
    func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType, fromShareItem shareItem: ShareItem, toApplication application: UIApplication) {
            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
        QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(type, withUserData: userData, toApplication: application)
    }

    @discardableResult func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType, withUserData userData: [String: String] = [String: String](), toApplication application: UIApplication) -> Bool {
        // add the quick actions version so that it is always in the user info
        var userData: [String: String] = userData
        userData[QuickActions.QuickActionsVersionKey] = QuickActions.QuickActionsVersion
        var dynamicShortcutItems = application.shortcutItems ?? [UIApplicationShortcutItem]()
        switch type {
        case .openLastBookmark:
            let openLastBookmarkShortcut = UIMutableApplicationShortcutItem(type: ShortcutType.openLastBookmark.type,
                localizedTitle: lastBookmarkTitle,
                localizedSubtitle: userData[QuickActions.TabTitleKey],
                icon: UIApplicationShortcutIcon(templateImageName: "quick_action_last_bookmark"),
                userInfo: userData as [String : NSSecureCoding]
            )
            if let index = (dynamicShortcutItems.firstIndex { $0.type == ShortcutType.openLastBookmark.type }) {
                dynamicShortcutItems[index] = openLastBookmarkShortcut
            } else {
                dynamicShortcutItems.append(openLastBookmarkShortcut)
            }
        default:
            log.warning("Cannot add static shortcut item of type \(type)")
            return false
        }
        application.shortcutItems = dynamicShortcutItems
        return true
    }

    func removeDynamicApplicationShortcutItemOfType(_ type: ShortcutType, fromApplication application: UIApplication) {
        guard var dynamicShortcutItems = application.shortcutItems,
            let index = (dynamicShortcutItems.firstIndex { $0.type == type.type }) else { return }

        dynamicShortcutItems.remove(at: index)
        application.shortcutItems = dynamicShortcutItems
    }

    // MARK: Handling Quick Actions
    @discardableResult func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem, withBrowserViewController bvc: BrowserViewController ) -> Bool {

        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard let shortCutType = ShortcutType(fullType: shortcutItem.type) else { return false }

        DispatchQueue.main.async {
            self.handleShortCutItemOfType(shortCutType, userData: shortcutItem.userInfo, browserViewController: bvc)
        }

        return true
    }

    fileprivate func handleShortCutItemOfType(_ type: ShortcutType, userData: [String: NSSecureCoding]?, browserViewController: BrowserViewController) {
        switch type {
        case .newTab:
            handleOpenNewTab(withBrowserViewController: browserViewController)
        case .openLastBookmark:
            if let urlToOpen = (userData?[QuickActions.TabURLKey] as? String)?.asURL {
                handleOpenURL(withBrowserViewController: browserViewController, urlToOpen: urlToOpen)
            }
        }
    }

    fileprivate func handleOpenNewTab(withBrowserViewController bvc: BrowserViewController) {
        bvc.openBlankNewTab(focusLocationField: true)
    }

    fileprivate func handleOpenURL(withBrowserViewController bvc: BrowserViewController, urlToOpen: URL) {
        // find out if bookmarked URL is currently open
        // if so, open to that tab,
        // otherwise, create a new tab with the bookmarked URL
        bvc.switchToTabForURLOrOpen(urlToOpen)
    }
}
