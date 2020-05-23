/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class DefaultSuggestedSites {
    public static let sites = [
        SuggestedSiteData(
            url: "gemini://gemini.circumlunar.space/",
            title: "Project Gemini"
        ),
        SuggestedSiteData(
            url: "gemini://gus.guru/",
            title: "GUS - Gemini Universal Search"
        ),
        SuggestedSiteData(
            url: "gemini://houston.coder.town",
            title: "Houston search engine"
        ),
        SuggestedSiteData(
            url: "gemini://gus.guru/known-hosts",
            title: "Known Gemini Hosts"
        )
    ]
}
