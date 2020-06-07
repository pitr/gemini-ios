/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Notification.Name {
    // Fired when the user finishes navigating to a page and the location has changed
    public static let OnLocationChange = Notification.Name("OnLocationChange")
  
    // MARK: Notification UserInfo Keys

    public static let DynamicFontChanged = Notification.Name("DynamicFontChanged")

    public static let ReachabilityStatusChanged = Notification.Name("ReachabilityStatusChanged")

    public static let HomePanelPrefsChanged = Notification.Name("HomePanelPrefsChanged")

    public static let DisplayThemeChanged = Notification.Name("DisplayThemeChanged")
}
