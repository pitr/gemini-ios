/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct PrefsKeys {
    public static let KeyNightModeButtonIsInMenu = "NightModeButtonIsInMenuPrefKey"
    public static let KeyNightModeStatus = "NightModeStatus"
    public static let KeyNightModeEnabledDarkTheme = "NightModeEnabledDarkTheme"
    public static let KeyMailToOption = "MailToOption"
    public static let IntroSeen = "IntroViewControllerSeen"
    public static let NumberOfTopSiteRows = "NumberOfTopSiteRows"
    public static let GeminiMaxImagesInline = "GeminiMaxImagesInline"
    public static let EnableSiteTheme = "EnableSiteTheme"

    public static let ContextMenuShowLinkPreviews = "showLinkPreviews"

    public static let NewTabCustomUrlPrefKey = "HomePageURLPref"
    //Activity Stream
    public static let KeyNewTab = "NewTabPrefKey"
}

public protocol Prefs {
    func getBranchPrefix() -> String
    func setTimestamp(_ value: Timestamp, forKey defaultName: String)
    func setLong(_ value: UInt64, forKey defaultName: String)
    func setLong(_ value: Int64, forKey defaultName: String)
    func setInt(_ value: Int32, forKey defaultName: String)
    func setString(_ value: String, forKey defaultName: String)
    func setBool(_ value: Bool, forKey defaultName: String)
    func setObject(_ value: Any?, forKey defaultName: String)
    func stringForKey(_ defaultName: String) -> String?
    func objectForKey<T: Any>(_ defaultName: String) -> T?
    func boolForKey(_ defaultName: String) -> Bool?
    func intForKey(_ defaultName: String) -> Int32?
    func timestampForKey(_ defaultName: String) -> Timestamp?
    func longForKey(_ defaultName: String) -> Int64?
    func unsignedLongForKey(_ defaultName: String) -> UInt64?
    func stringArrayForKey(_ defaultName: String) -> [String]?
    func arrayForKey(_ defaultName: String) -> [Any]?
    func dictionaryForKey(_ defaultName: String) -> [String: Any]?
    func removeObjectForKey(_ defaultName: String)
    func clearAll()
}
