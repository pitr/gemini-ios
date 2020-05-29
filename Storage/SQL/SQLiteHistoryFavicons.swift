/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftyJSON
import Shared
import XCGLogger

// Used as backgrounds for favicons
public let DefaultFaviconBackgroundColors = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

private let log = Logger.syncLogger

// Set up for downloading web content for parsing.
// NOTE: We use the desktop UA to try and get hi-res icons.
private var urlSession: URLSession = makeURLSession(userAgent: UserAgent.desktopUserAgent(), configuration: URLSessionConfiguration.default, timeout: 5)

// If all else fails, this is the default "default" icon.
private var defaultFavicon: UIImage = {
    return UIImage(named: "defaultFavicon")!
}()

// An in-memory cache of "default" favicons keyed by the
// first character of a site's domain name.
private var defaultFaviconImageCache = [String: UIImage]()

class FaviconLookupError: MaybeErrorType {
    let siteURL: String
    init(siteURL: String) {
        self.siteURL = siteURL
    }
    var description: String {
        return "Unable to find favicon for site URL: \(siteURL)"
    }
}

extension SQLiteHistory: Favicons {
    func getFaviconsForURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = """
            SELECT iconID, iconURL, iconDate
            FROM (
                SELECT iconID, iconURL, iconDate
                FROM view_favicons_widest, history
                WHERE history.id = siteID AND history.url = ?
                UNION ALL
                SELECT favicons.id AS iconID, url as iconURL, date as iconDate
                FROM favicons, favicon_site_urls
                WHERE favicons.id = favicon_site_urls.faviconID AND favicon_site_urls.site_url = ?
            ) LIMIT 1
            """

        let args: Args = [url, url]
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    public func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        return self.favicons.insertOrUpdateFavicon(icon)
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        func doChange(_ query: String, args: Args?) -> Deferred<Maybe<Int>> {
            return db.withConnection { conn -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdateFaviconInTransaction(icon, conn: conn)

                // Now set up the mapping.
                try conn.executeChange(query, withArgs: args)

                guard let faviconID = id else {
                    let err = DatabaseError(description: "Error adding favicon. ID = 0")
                    log.error("addFavicon(_:, forSite:) encountered an error: \(err.localizedDescription)")
                    throw err
                }

                return faviconID
            }
        }

        let siteSubselect = "(SELECT id FROM history WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM favicons WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO favicon_sites (siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args: args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args: args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args: args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args: args)
    }

    public func getFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        return generateDefaultFaviconImage(forSite: site)
    }

    // Generates a "default" favicon based on the first character in the
    // site's domain name or gets an already-generated icon from the cache.
    fileprivate func generateDefaultFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()

        DispatchQueue.main.async {
            guard let url = URL(string: site.url), let character = url.baseDomain?.first else {
                deferred.fill(Maybe(success: defaultFavicon))
                return
            }

            let faviconLetter = String(character).uppercased()

            if let cachedFavicon = defaultFaviconImageCache[faviconLetter] {
                deferred.fill(Maybe(success: cachedFavicon))
                return
            }

            func generateBackgroundColor(forURL url: URL) -> UIColor {
                guard let hash = url.baseDomain?.hashValue else {
                    return UIColor.Photon.Grey50
                }
                let index = abs(hash) % (DefaultFaviconBackgroundColors.count - 1)
                let colorHex = DefaultFaviconBackgroundColors[index]
                return UIColor(colorString: colorHex)
            }

            var image = UIImage()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            label.text = faviconLetter
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
            label.textColor = UIColor.Photon.White100
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
            let rect = CGRect(origin: .zero, size: label.bounds.size)
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(generateBackgroundColor(forURL: url).cgColor)
            context.fill(rect)
            label.layer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            defaultFaviconImageCache[faviconLetter] = image
            deferred.fill(Maybe(success: image))
        }
        return deferred
    }
}
