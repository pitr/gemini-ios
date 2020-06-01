/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

open class SuggestedSite: Site {
    override open var tileURL: URL {
        return URL(string: url as String) ?? URL(string: "about:blank")!
    }

    init(data: SuggestedSiteData) {
        super.init(url: data.url, title: data.title, bookmarked: nil)
        self.guid = "default" + data.title // A guid is required in the case the site might become a pinned site
    }
}

open class SuggestedSites {
    public static func defaults() -> [SuggestedSite] {
        let sites = DefaultSuggestedSites.sites
        return sites.map({ data -> SuggestedSite in
            return SuggestedSite(data: data)
        })
    }
}

public struct SuggestedSiteData {
    var url: String
    var title: String
}
