/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import CoreSpotlight
import MobileCoreServices
import WebKit

private let browsingActivityType: String = "com.pitr.ios.gemini.browsing"

class UserActivityHandler {
    init() {
        register(self, forTabEvents: .didClose, .didLoseFocus, .didGainFocus, .didChangeURL)
    }

    fileprivate func setUserActivityForTab(_ tab: Tab, url: URL) {
        guard url.isWebPage(includeDataURIs: false), !InternalURL.isValid(url: url) else {
            tab.userActivity?.resignCurrent()
            tab.userActivity = nil
            return
        }

        tab.userActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: browsingActivityType)
        if url.scheme != "gemini" {
            userActivity.webpageURL = url
        }
        userActivity.becomeCurrent()

        tab.userActivity = userActivity
    }
}

extension UserActivityHandler: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
        tab.userActivity?.becomeCurrent()
    }

    func tabDidLoseFocus(_ tab: Tab) {
        tab.userActivity?.resignCurrent()
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        setUserActivityForTab(tab, url: url)
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.userActivity else {
            return
        }
        tab.userActivity = nil
        userActivity.invalidate()
    }
}
