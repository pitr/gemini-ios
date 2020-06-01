/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

// Used as backgrounds for favicons
public let DefaultFaviconBackgroundColors = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

public class Favicons {
    public init() {
        
    }
    private var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    private var defaultFaviconImageCache = [String: UIImage]()

    // Generates a "default" favicon based on the first character in the
    // site's domain name or gets an already-generated icon from the cache.
    public func generateDefaultFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()

        DispatchQueue.main.async {
            guard let url = URL(string: site.url), let character = url.baseDomain?.first else {
                deferred.fill(Maybe(success: self.defaultFavicon))
                return
            }

            let faviconLetter = String(character).uppercased()

            if let cachedFavicon = self.defaultFaviconImageCache[faviconLetter] {
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

            self.defaultFaviconImageCache[faviconLetter] = image
            deferred.fill(Maybe(success: image))
        }
        return deferred
    }
}
