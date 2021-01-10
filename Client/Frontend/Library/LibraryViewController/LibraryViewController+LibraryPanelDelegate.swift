/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared

extension LibraryViewController: LibraryPanelDelegate {
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL) {
        delegate?.libraryPanelDidRequestToOpenInNewTab(url)
    }

    func libraryPanel(didSelectURL url: URL, historyType: HistoryType) {
        delegate?.libraryPanel(didSelectURL: url, historyType: historyType)
        dismiss(animated: true, completion: nil)
    }

    func libraryPanel(didSelectURLString url: String, historyType: HistoryType) {
        // If we can't get a real URL out of what should be a URL, we let the user's
        // default search engine give it a shot.
        // Typically we'll be in this state if the user has tapped a bookmarked search template
        // (e.g., "http://foo.com/bar/?query=%s"), and this will get them the same behavior as if
        // they'd copied and pasted into the URL bar.
        // See BrowserViewController.urlBar:didSubmitText:.
        guard let url = URIFixup.getURL(url) ?? profile.searchEngines.defaultEngine.searchURLForQuery(url) else {
            Logger.browserLogger.warning("Invalid URL, and couldn't generate a search URL for it.")
            return
        }
        return self.libraryPanel(didSelectURL: url, historyType: historyType)
    }
}
