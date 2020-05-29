/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

/*
 This only makes sense if you look at the structure of List.json
*/
class DefaultSearchPrefs {
    fileprivate let defaultSearchList: [String]
    fileprivate let globalDefaultEngine: String

    public init?(with filePath: URL) {
        guard let searchManifest = try? String(contentsOf: filePath) else {
            assertionFailure("Search list not found. Check bundle")
            return nil
        }
        let json = JSON(parseJSON: searchManifest)
        // Split up the JSON into useful parts
        guard let searchList = json["default"]["visibleDefaultEngines"].array?.compactMap({ $0.string }),
            let engine = json["default"]["searchDefault"].string else {
                assertionFailure("Defaults are not set up correctly in List.json")
                return nil
        }
        defaultSearchList = searchList
        globalDefaultEngine = engine
    }

    /*
     Returns an array of the visibile engines. It overrides any of the returned engines from the regionOverrides list
     Each langauge in the locales list has a default list of engines and then a region override list.
     */
    open func visibleDefaultEngines() -> [String] {
        return defaultSearchList
    }

    /*
     Returns the default search given the possible locales and region
     The list.json locales list contains searchDefaults for a few locales.
     Create a list of these and return the last one. The globalDefault acts as the fallback in case the list is empty.
     */
    open func searchDefault() -> String {
        return globalDefaultEngine
    }
}
