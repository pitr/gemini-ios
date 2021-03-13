/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

protocol LibraryPanel: Themeable {
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }
}

struct LibraryPanelUX {
    static let EmptyTabContentOffset = -180
}

protocol LibraryPanelDelegate: AnyObject {
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL)
    func libraryPanel(didSelectURL url: URL, historyType: HistoryType)
    func libraryPanel(didSelectURLString url: String, historyType: HistoryType)
}

enum LibraryPanelType: Int {
    case bookmarks = 0
    case history = 1
    case certificates = 2
}

/**
 * Data for identifying and constructing a LibraryPanel.
 */
class LibraryPanelDescriptor {
    var viewController: UIViewController?
    var navigationController: UINavigationController?

    fileprivate let makeViewController: (_ profile: Profile) -> UIViewController
    fileprivate let profile: Profile

    let imageName: String
    let activeImageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    init(makeViewController: @escaping ((_ profile: Profile) -> UIViewController), profile: Profile, imageName: String, accessibilityLabel: String, accessibilityIdentifier: String) {
        self.makeViewController = makeViewController
        self.profile = profile
        self.imageName = "panelIcon" + imageName
        self.activeImageName = self.imageName + "-active"
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func setup() {
        guard viewController == nil else { return }
        let viewController = makeViewController(profile)
        self.viewController = viewController
        navigationController = ThemedNavigationController(rootViewController: viewController)
    }
}

class LibraryPanels {
    fileprivate let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    lazy var enabledPanels = [
        LibraryPanelDescriptor(
            makeViewController: { profile in
                return BookmarksPanel(profile: profile)
            },
            profile: profile,
            imageName: "Bookmarks",
            accessibilityLabel: Strings.LibraryBookmarksAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.Bookmarks"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                return HistoryPanel(profile: profile)
            },
            profile: profile,
            imageName: "History",
            accessibilityLabel: Strings.LibraryHistoryAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.History"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                return CertificatesPanel(profile: profile)
            },
            profile: profile,
            imageName: "Certificates",
            accessibilityLabel: Strings.LibraryCertificatesAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.Certificates"),
    ]
}
