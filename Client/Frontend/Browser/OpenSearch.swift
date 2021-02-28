/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class OpenSearchEngine: NSObject, NSCoding {
    static let PreferredIconSize = 30

    let shortName: String
    let image: UIImage
    let isCustomEngine: Bool
    let searchTemplate: String

    fileprivate let SearchTermComponent = "{searchTerms}"
    fileprivate let LocaleTermComponent = "{moz:locale}"

    fileprivate lazy var searchQueryComponentKey: String? = self.getQueryArgFromTemplate()

    init(shortName: String, image: UIImage, searchTemplate: String, isCustomEngine: Bool) {
        self.shortName = shortName
        self.image = image
        self.searchTemplate = searchTemplate
        self.isCustomEngine = isCustomEngine
    }

    required init?(coder aDecoder: NSCoder) {
        // this catches the cases where bool encoded in Swift 2 needs to be decoded with decodeObject, but a Bool encoded in swift 3 needs
        // to be decoded using decodeBool. This catches the upgrade case to ensure that we are always able to fetch a keyed valye for isCustomEngine
        // http://stackoverflow.com/a/40034694
        let isCustomEngine = aDecoder.decodeAsBool(forKey: "isCustomEngine")
        guard let searchTemplate = aDecoder.decodeObject(forKey: "searchTemplate") as? String,
            let shortName = aDecoder.decodeObject(forKey: "shortName") as? String,
            let image = aDecoder.decodeObject(forKey: "image") as? UIImage else {
                assertionFailure()
                return nil
        }

        self.searchTemplate = searchTemplate
        self.shortName = shortName
        self.isCustomEngine = isCustomEngine
        self.image = image
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(searchTemplate, forKey: "searchTemplate")
        aCoder.encode(shortName, forKey: "shortName")
        aCoder.encode(isCustomEngine, forKey: "isCustomEngine")
        aCoder.encode(image, forKey: "image")
    }

    /**
     * Returns the search URL for the given query.
     */
    func searchURLForQuery(_ query: String) -> URL? {
        return getURLFromTemplate(searchTemplate, query: query)
    }

    /**
     * Return the arg that we use for searching for this engine
     * Problem: the search terms may not be a query arg, they may be part of the URL - how to deal with this?
     **/
    fileprivate func getQueryArgFromTemplate() -> String? {
        // we have the replace the templates SearchTermComponent in order to make the template
        // a valid URL, otherwise we cannot do the conversion to NSURLComponents
        // and have to do flaky pattern matching instead.
        let placeholder = "PLACEHOLDER"
        let template = searchTemplate.replacingOccurrences(of: SearchTermComponent, with: placeholder)
        var components = URLComponents(string: template)
        
        if let retVal = extractQueryArg(in: components?.queryItems, for: placeholder) {
            return retVal
        } else {
            // Query arg may be exist inside fragment
            components = URLComponents()
            components?.query = URL(string: template)?.fragment
            return extractQueryArg(in: components?.queryItems, for: placeholder)
        }
    }
    
    fileprivate func extractQueryArg(in queryItems: [URLQueryItem]?, for placeholder: String) -> String? {
        let searchTerm = queryItems?.filter { item in
            return item.value == placeholder
        }
        return searchTerm?.first?.name
    }
    
    /**
     * check that the URL host contains the name of the search engine somewhere inside it
     **/
    fileprivate func isSearchURLForEngine(_ url: URL?) -> Bool {
        guard let urlHost = url?.shortDisplayString,
            let queryEndIndex = searchTemplate.range(of: "?")?.lowerBound,
            let templateURL = URL(string: String(searchTemplate[..<queryEndIndex])) else { return false }
        return urlHost == templateURL.shortDisplayString
    }

    /**
     * Returns the query that was used to construct a given search URL
     **/
    func queryForSearchURL(_ url: URL?) -> String? {
        guard isSearchURLForEngine(url), let key = searchQueryComponentKey else { return nil }
        
        if let value = url?.getQuery()[key] {
            return value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        } else {
            // If search term could not found in query, it may be exist inside fragment
            var components = URLComponents()
            components.query = url?.fragment?.removingPercentEncoding
            
            guard let value = components.url?.getQuery()[key] else { return nil }
            return value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        }
    }

    fileprivate func getURLFromTemplate(_ searchTemplate: String, query: String) -> URL? {
        if let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .SearchTermsAllowed) {
            // Escape the search template as well in case it contains not-safe characters like symbols
            let templateAllowedSet = NSMutableCharacterSet()
            templateAllowedSet.formUnion(with: .URLAllowed)

            // Allow brackets since we use them in our template as our insertion point
            templateAllowedSet.formUnion(with: CharacterSet(charactersIn: "{}"))

            if let encodedSearchTemplate = searchTemplate.addingPercentEncoding(withAllowedCharacters: templateAllowedSet as CharacterSet) {
                let localeString = Locale.current.identifier
                let urlString = encodedSearchTemplate
                    .replacingOccurrences(of: SearchTermComponent, with: escapedQuery, options: .literal, range: nil)
                    .replacingOccurrences(of: LocaleTermComponent, with: localeString, options: .literal, range: nil)
                return URL(string: urlString)
            }
        }

        return nil
    }
}

class OpenSearchParser {
    static func parse() -> [OpenSearchEngine] {
        if let path = Bundle.main.path(forResource: "SearchPlugins", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            return dictRoot.compactMap({ dict -> OpenSearchEngine? in
                guard let searchDict = dict as? [String: String],
                   let name = searchDict["name"],
                   let url = searchDict["url"] else {
                    return nil
                }
                var uiImage: UIImage
                if let imageValue = searchDict["img"],
                   !imageValue.isEmpty,
                   let imageURL = URL(string: imageValue),
                   let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage.imageFromDataThreadSafe(imageData) {
                    uiImage = image
                } else if let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!),
                          url.isWebPage() {
                    uiImage = FaviconFetcher.letter(forUrl: url)
                } else {
                    print("Error: Invalid search image data")
                    return nil
                }

                return OpenSearchEngine(shortName: name, image: uiImage, searchTemplate: url, isCustomEngine: false)
            })
        }
        return []
    }
}
