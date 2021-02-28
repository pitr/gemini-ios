/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class FaviconFetcher {
    fileprivate static var hostToFaviconCache = [String: UIImage]()
    public static var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    typealias BundledIconType = (bgcolor: UIColor, filePath: String)

    // Create (or return from cache) a fallback image for a site based on the first letter of the site's domain
    // Letter is white on a colored background
    public class func letter(forUrl url: URL) -> UIImage {
        guard let host = url.host, let character = host.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = hostToFaviconCache[host] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
        faviconLabel.textColor = UIColor(rgb: 0xffffff)
        faviconLabel.backgroundColor = color(forUrl: url)
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        hostToFaviconCache[host] = faviconImage
        return faviconImage
    }

    // Returns a color based on the url's hash
    public class func color(forUrl url: URL) -> UIColor {
        guard let hash = url.host?.md5, hash.count > 2 else {
            return UIColor(rgb: 0x737373)
        }
        let hue = CGFloat(hash[0]) + CGFloat(hash[1]) / 510.0
        let saturation = CGFloat(hash[2]) / 255.0
        return UIColor(hue: hue, saturation: saturation, brightness: 0.85, alpha: 1.0)
    }
}
