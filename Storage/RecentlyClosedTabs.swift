/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

open class ClosedTabsStore {
    let prefs: Prefs

    lazy open var tabs: [ClosedTab] = {
        guard let tabsArray: Data = self.prefs.objectForKey("recentlyClosedTabs") as Any? as? Data,
              let unarchivedArray = NSKeyedUnarchiver.unarchiveObject(with: tabsArray) as? [ClosedTab] else {
            return []
        }
        return unarchivedArray
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    open func addTab(_ url: URL, title: String?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title ?? "")
        tabs.insert(recentlyClosedTab, at: 0)
        if tabs.count > 5 {
            tabs.removeLast()
        }
        let archivedTabsArray = NSKeyedArchiver.archivedData(withRootObject: tabs)
        prefs.setObject(archivedTabsArray, forKey: "recentlyClosedTabs")
    }

    open func clearTabs() {
        prefs.removeObjectForKey("recentlyClosedTabs")
        tabs = []
    }
}

open class ClosedTab: NSObject, NSCoding {
    public let url: URL
    public let title: String?

    var jsonDictionary: [String: Any] {
        let title = (self.title ?? "")
        let json: [String: Any] = ["title": title, "url": url]
        return json
    }

    init(url: URL, title: String?) {
        assert(Thread.isMainThread)
        self.title = title
        self.url = url
        super.init()
    }

    required convenience public init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: "url") as? URL,
              let title = coder.decodeObject(forKey: "title") as? String else { return nil }

        self.init(url: url,title: title)
    }

    open func encode(with coder: NSCoder) {
        coder.encode(url, forKey: "url")
        coder.encode(title, forKey: "title")
    }
}
