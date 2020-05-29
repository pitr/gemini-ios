/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

public extension UIImageView {

    func setImageAndBackground(website: URL?) {
        backgroundColor = nil
        let defaults = fallbackFavicon(forUrl: website)
        self.image = defaults.image
    }

    func setFavicon(forSite site: Site) {
        setImageAndBackground(website: site.tileURL)
    }

    private func fallbackFavicon(forUrl url: URL?) -> (image: UIImage, color: UIColor) {
        if let url = url {
            return (FaviconFetcher.letter(forUrl: url), FaviconFetcher.color(forUrl: url))
        } else {
            return (FaviconFetcher.defaultFavicon, .white)
        }
    }
    
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}
