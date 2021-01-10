/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import XCGLogger
import SnapKit

private let log = Logger.browserLogger
private let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"

// MARK: -  Lifecycle
struct GeminiHomeUX {
    static let rowSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 20)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    static let SectionInsetsForIpad: CGFloat = 101
    static let SectionInsetsForIphone: CGFloat = 20
    static let MinimumInsets: CGFloat = 20
    static let TopSitesInsets: CGFloat = 6
    static let LibraryShortcutsHeight: CGFloat = 100
    static let LibraryShortcutsMaxWidth: CGFloat = 350
}
/*
 Size classes are the way Apple requires us to specify our UI.
 Split view on iPad can make a landscape app appear with the demensions of an iPhone app
 Use UXSizeClasses to specify things like offsets/itemsizes with respect to size classes
 For a primer on size classes https://useyourloaf.com/blog/size-classes/
 */
struct UXSizeClasses {
    var compact: CGFloat
    var regular: CGFloat
    var unspecified: CGFloat

    init(compact: CGFloat, regular: CGFloat, other: CGFloat) {
        self.compact = compact
        self.regular = regular
        self.unspecified = other
    }

    subscript(sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        switch sizeClass {
            case .compact:
                return self.compact
            case .regular:
                return self.regular
            case .unspecified:
                return self.unspecified
            @unknown default:
                fatalError()
        }

    }
}

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL)
    func homePanel(didSelectURL url: URL, historyType: HistoryType)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
}

protocol HomePanel: Themeable {
    var homePanelDelegate: HomePanelDelegate? { get set }
}

enum HomePanelType: Int {
    case topSites = 0

    var internalUrl: URL {
        let aboutUrl: URL! = URL(string: "\(InternalURL.baseUrl)/\(AboutHomeHandler.path)")
        return URL(string: "#panel=\(self.rawValue)", relativeTo: aboutUrl)!
    }
}

protocol HomePanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let contextMenu = PhotonActionSheet(site: site, actions: actions)
        contextMenu.modalPresentationStyle = .overFullScreen
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL)
        }

        return [openInNewTabAction]
    }
}

class GeminiHomeViewController: UICollectionViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    fileprivate let profile: Profile
    fileprivate let flowLayout = UICollectionViewFlowLayout()

    fileprivate lazy var topSitesManager: ASHorizontalScrollCellManager = {
        let manager = ASHorizontalScrollCellManager()
        return manager
    }()

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.topSitesManager
        return customCell
    }()

    init(profile: Profile) {
        self.profile = profile
        super.init(collectionViewLayout: flowLayout)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self

        collectionView?.addGestureRecognizer(longPressRecognizer)

        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allValues.forEach { self.collectionView?.register(Section($0.rawValue).cellType, forCellWithReuseIdentifier: Section($0.rawValue).cellIdentifier) }
        self.collectionView?.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        self.collectionView?.register(ASFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView?.keyboardDismissMode = .onDrag

        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            //The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: { _ in
            // Workaround: label positions are not correct without additional reload
            self.collectionView?.reloadData()
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
    }

    @objc func reload(notification: Notification) {
        reloadAll()
    }

    func applyTheme() {
        collectionView?.backgroundColor = UIColor.theme.homePanel.topSitesBackground
        topSiteCell.collectionView.reloadData()
        if let collectionView = self.collectionView, collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.reloadData()
        }
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }
}

// MARK: -  Section management
extension GeminiHomeViewController {
    enum Section: Int {
        case topSites
        case libraryShortcuts

        static let count = 2
        static let allValues = [topSites, libraryShortcuts]

        var title: String? {
            switch self {
            case .topSites: return Strings.ASTopSitesTitle
            case .libraryShortcuts: return Strings.AppMenuLibraryTitleString
            }
        }

        var headerHeight: CGSize {
            return CGSize(width: 50, height: 40)
        }

        var headerImage: UIImage? {
            switch self {
            case .topSites: return UIImage.templateImageNamed("menu-panel-TopSites")
            case .libraryShortcuts: return UIImage.templateImageNamed("menu-library")
            }
        }

        var footerHeight: CGSize {
            switch self {
            case .topSites, .libraryShortcuts: return CGSize(width: 50, height: 5)
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .topSites: return 0 //calculated dynamically
            case .libraryShortcuts: return GeminiHomeUX.LibraryShortcutsHeight
            }
        }

        /*
         There are edge cases to handle when calculating section insets
        - An iPhone 7+ is considered regular width when in landscape
        - An iPad in 66% split view is still considered regular width
         */
        func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var currentTraits = traits
            if (traits.horizontalSizeClass == .regular && UIScreen.main.bounds.size.width != frameWidth) || UIDevice.current.userInterfaceIdiom == .phone {
                currentTraits = UITraitCollection(horizontalSizeClass: .compact)
            }
            var insets = GeminiHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

            switch self {
            case .libraryShortcuts:
                let window = UIApplication.shared.keyWindow
                let safeAreaInsets = window?.safeAreaInsets.left ?? 0
                insets += GeminiHomeUX.MinimumInsets + safeAreaInsets
                return insets
            case .topSites:
                insets += GeminiHomeUX.TopSitesInsets
                return insets
            }
        }

        func numberOfItemsForRow(_ traits: UITraitCollection) -> CGFloat {
            switch self {
            case .topSites, .libraryShortcuts:
                return 1
            }
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2

            switch self {
            case .topSites, .libraryShortcuts:
                return CGSize(width: frameWidth - inset, height: height)
            }
        }

        var headerView: UIView? {
            let view = ASHeaderView()
            view.title = title
            return view
        }

        var cellIdentifier: String {
            switch self {
            case .topSites: return "TopSiteCell"
            case .libraryShortcuts: return  "LibraryShortcutsCell"
            }
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .topSites: return ASHorizontalScrollCell.self
            case .libraryShortcuts: return ASLibraryCell.self
            }
        }

        init(at indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }
}

// MARK: -  Tableview Delegate
extension GeminiHomeViewController: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
                view.iconView.isHidden = false
                view.iconView.image = Section(indexPath.section).headerImage
                let title = Section(indexPath.section).title
                switch Section(indexPath.section) {
                case .topSites:
                    view.title = title
                    view.titleLabel.accessibilityIdentifier = "topSitesTitle"
                    view.moreButton.isHidden = true
                    return view
                case .libraryShortcuts:
                    view.title = title
                    view.titleLabel.accessibilityIdentifier = "libraryTitle"
                    view.moreButton.isHidden = true
                    return view
            }
        case UICollectionView.elementKindSectionFooter:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath) as! ASFooterView
                switch Section(indexPath.section) {
                case .topSites:
                    return view
                case .libraryShortcuts:
                    view.separatorLineView?.isHidden = true
                    return view
            }
            default:
                return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.longPressRecognizer.isEnabled = false
        selectItemAtIndex(indexPath.item, inSection: Section(indexPath.section))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch Section(indexPath.section) {
        case .topSites:
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)
        case .libraryShortcuts:
            let numberofshortcuts: CGFloat = 4
            let titleSpacing: CGFloat = 10
            let width = min(GeminiHomeUX.LibraryShortcutsMaxWidth, cellSize.width)
            return CGSize(width: width, height: (width / numberofshortcuts) + titleSpacing)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(section) {
        case .topSites:
            return Section(section).headerHeight
        case .libraryShortcuts:
            return Section(section).headerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch Section(section) {
        case .topSites:
            return Section(section).footerHeight
        case .libraryShortcuts:
            return Section(section).footerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GeminiHomeUX.rowSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        return UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        homePanelDelegate?.homePanel(didSelectURL: url, historyType: .bookmark)
    }
}

// MARK: - Tableview Data Source
extension GeminiHomeViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numItems: CGFloat = GeminiHomeUX.numberOfItemsPerRowForSizeClassIpad[self.traitCollection.horizontalSizeClass]
        if UIApplication.shared.statusBarOrientation.isPortrait {
            numItems = numItems - 1
        }
        if self.traitCollection.horizontalSizeClass == .compact && UIApplication.shared.statusBarOrientation.isLandscape {
            numItems = numItems - 1
        }
        switch Section(section) {
        case .topSites:
            return topSitesManager.content.isEmpty ? 0 : 1
        case .libraryShortcuts:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
        case .topSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .libraryShortcuts:
            return configureLibraryShortcutsCell(cell, forIndexPath: indexPath)
        }
    }

    func configureLibraryShortcutsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let libraryCell = cell as! ASLibraryCell
        let targets = [#selector(openBookmarks), #selector(openHistory), #selector(openCertificates)]
        libraryCell.libraryButtons.map({ $0.button }).zip(targets).forEach { (button, selector) in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: selector, for: .touchUpInside)
        }
        libraryCell.applyTheme()
        return cell
    }

    //should all be collectionview
    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        return cell
    }
}

let ActivityStreamTopSiteCacheSize: Int32 = 32

// MARK: - Data Management
extension GeminiHomeViewController {

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    func reloadAll() {
        self.getTopSites()
        // If there is no pending cache update and highlights are empty. Show the onboarding screen
        self.collectionView?.reloadData()
    }

    func getTopSites() {
        let numRows = max(self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
        let mySites = self.profile.db.getTopSitesWithLimit(UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16)
        let pinned = self.profile.db.getPinnedTopSites()

        // How sites are merged together. We compare against the url's base domain. example m.youtube.com is compared against `youtube.com`
        let unionOnURL = { (site: Site) -> String in
            return URL(string: site.url)?.normalizedHost ?? ""
        }

        // Fetch the default sites
        let defaultSites = self.defaultTopSites()
        // create PinnedSite objects. used by the view layer to tell topsites apart
        let pinnedSites: [Site] = pinned.map({ PinnedSite(site: $0) })

        // Merge default topsites with a user's topsites.
        let mergedSites = mySites.union(defaultSites, f: unionOnURL)

        // Merge pinnedSites with sites from the previous step
        let newSites = pinnedSites.union(mergedSites, f: unionOnURL)

        self.topSitesManager.currentTraits = self.view.traitCollection
        let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()
        if newSites.count > Int(ActivityStreamTopSiteCacheSize) {
            self.topSitesManager.content = Array(newSites[0..<Int(ActivityStreamTopSiteCacheSize)])
        } else {
            self.topSitesManager.content = newSites
        }

        if newSites.count > maxItems {
            self.topSitesManager.content =  Array(newSites[0..<maxItems])
        }

        self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
            self.longPressRecognizer.isEnabled = false
            self.showSiteWithURLHandler(url as URL)
        }
    }

    func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else {
            return
        }
        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
            deleteTileForSuggestedSite(url)
        }
        _ = profile.db.removeHostFromTopSites(host)
    }

    func pinTopSite(_ site: Site) {
        guard profile.db.addPinnedTopSite(site).isSuccess else { return }
    }

    func removePinTopSite(_ site: Site) {
        _ = profile.db.removeFromPinnedTopSites(site)
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.defaults()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let indexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        switch Section(indexPath.section) {
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenu(for: topSiteIndexPath)
        case .libraryShortcuts:
            return
        }
    }

    fileprivate func fetchBookmarkStatus(for site: Site, with indexPath: IndexPath, forSection section: Section, completionHandler: @escaping () -> Void) {
        let isBookmarked = self.profile.db.getBookmarksWithURL(url: site.url).count > 0
        site.setBookmarked(isBookmarked)
        completionHandler()
    }

    func selectItemAtIndex(_ index: Int, inSection section: Section) {
        switch section {
        case .topSites:
            return
        case .libraryShortcuts:
            return
        }
    }
}

extension GeminiHomeViewController {
    @objc func openBookmarks() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
    }

    @objc func openHistory() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
    }

    @objc func openCertificates() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .certificates)
    }
}

extension GeminiHomeViewController: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {

        fetchBookmarkStatus(for: site, with: indexPath, forSection: Section(indexPath.section)) {
            guard let contextMenu = completionHandler() else { return }
            self.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        switch Section(indexPath.section) {
        case .topSites:
            return topSitesManager.content[indexPath.item]
        case .libraryShortcuts:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }
        var sourceView: UIView?
        switch Section(indexPath.section) {
        case .topSites:
            if let topSiteCell = self.collectionView?.cellForItem(at: IndexPath(row: 0, section: 0)) as? ASHorizontalScrollCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: indexPath)
            }
        case .libraryShortcuts:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL)
        }

        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { _, _ in
                if self.profile.db.deleteBookmarksWithURL(url: site.url).isSuccess {
                    site.setBookmarked(false)
                }
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { _, _ in
                let shareItem = ShareItem(url: site.url, title: site.title)
                _ = self.profile.db.createBookmark(parentGUID: Bookmark.RootGUID, url: shareItem.url, title: shareItem.title)

                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                    withUserData: userData,
                                                                                    toApplication: .shared)
                site.setBookmarked(true)
            })
        }

        let shareAction = PhotonActionSheetItem(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { _, _ in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController({ (_, _) in })
            if UI_USER_INTERFACE_IDIOM() == .pad, let popoverController = controller.popoverPresentationController {
                let cellRect = sourceView?.frame ?? .zero
                let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width/2, y: cellFrameInSuperview.height/2), size: .zero)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self
            }
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { _, _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: Strings.RemovePinTopsiteActionTitle, iconString: "action_unpin", handler: { _, _ in
            self.removePinTopSite(site)
        })

        let topSiteActions: [PhotonActionSheetItem]
        if let _ = site as? PinnedSite {
            topSiteActions = [removePinTopSite]
        } else {
            topSiteActions = [pinTopSite, removeTopSiteAction]
        }

        var actions = [openInNewTabAction, bookmarkAction, shareAction]

        switch Section(indexPath.section) {
            case .topSites: actions.append(contentsOf: topSiteActions)
            case .libraryShortcuts: break
        }
        return actions
    }
}

extension GeminiHomeViewController: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Section Header View
private struct GeminiHomeHeaderViewUX {
    static var SeparatorColor: UIColor { return UIColor.theme.homePanel.separator }
    static let TextFont = DynamicFontHelper.defaultHelper.SmallSizeHeavyWeightAS
    static let ButtonFont = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
    static let SeparatorHeight = 0.5
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? GeminiHomeUX.SectionInsetsForIpad + GeminiHomeUX.MinimumInsets : GeminiHomeUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
}

class ASFooterView: UICollectionReusableView {

    var separatorLineView: UIView?
    var leftConstraint: Constraint? //This constraint aligns content (Titles, buttons) between all sections.

    override init(frame: CGRect) {
        super.init(frame: frame)

        let separatorLine = UIView()
        self.backgroundColor = UIColor.clear
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(GeminiHomeHeaderViewUX.SeparatorHeight)
            leftConstraint = make.leading.equalTo(self.safeArea.leading).inset(insets).constraint
            make.trailing.equalTo(self.safeArea.trailing).inset(insets)
            make.top.equalTo(self.snp.top)
        }
        separatorLineView = separatorLine
        applyTheme()
    }

    var insets: CGFloat {
        return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? GeminiHomeHeaderViewUX.Insets : GeminiHomeUX.MinimumInsets
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        separatorLineView?.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // update the insets every time a layout happens.Insets change depending on orientation or size (ipad split screen)
        leftConstraint?.update(offset: insets)
    }
}

extension ASFooterView: Themeable {
    func applyTheme() {
        separatorLineView?.backgroundColor = GeminiHomeHeaderViewUX.SeparatorColor
    }
}

class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 4

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = GeminiHomeHeaderViewUX.TextFont
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = GeminiHomeHeaderViewUX.ButtonFont
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        return button
    }()

    lazy fileprivate var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.Photon.Grey50
        imageView.isHidden = true
        return imageView
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var leftConstraint: Constraint?
    var rightConstraint: Constraint?

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? GeminiHomeHeaderViewUX.Insets : GeminiHomeUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        iconView.isHidden = true
        iconView.tintColor =  UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)
        addSubview(iconView)
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top).offset(ASHeaderView.verticalInsets)
            make.bottom.equalToSuperview().offset(-ASHeaderView.verticalInsets)
            self.rightConstraint = make.trailing.equalTo(self.safeArea.trailing).inset(-titleInsets).constraint
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(5)
            make.trailing.equalTo(moreButton.snp.leading).inset(-GeminiHomeHeaderViewUX.TitleTopInset)
            make.top.equalTo(self.snp.top).offset(ASHeaderView.verticalInsets)
            make.bottom.equalToSuperview().offset(-ASHeaderView.verticalInsets)
        }
        iconView.snp.makeConstraints { make in
            self.leftConstraint = make.leading.equalTo(self.safeArea.leading).inset(titleInsets).constraint
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(16)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftConstraint?.update(offset: titleInsets)
        rightConstraint?.update(offset: -titleInsets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LibraryShortcutView: UIView {
    static let spacing: CGFloat = 15

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(self).offset(-LibraryShortcutView.spacing)
            make.height.equalTo(self.snp.width).offset(-LibraryShortcutView.spacing)
        }
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7
        title.lineBreakMode = .byTruncatingTail
        title.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        title.textAlignment = .center
        title.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        button.imageView?.contentMode = .scaleToFill
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: LibraryShortcutView.spacing)
        button.tintColor = .white
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        button.layer.cornerRadius = (self.frame.width - LibraryShortcutView.spacing) / 2
        super.layoutSubviews()
    }
}

class ASLibraryCell: UICollectionViewCell, Themeable {

    var mainView = UIStackView()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []

    let bookmarks = LibraryPanel(title: Strings.AppMenuBookmarksTitleString, image: UIImage.templateImageNamed("menu-Bookmark"), color: UIColor.Photon.Blue50)
    let history = LibraryPanel(title: Strings.AppMenuHistoryTitleString, image: UIImage.templateImageNamed("menu-panel-History"), color: UIColor.Photon.Orange50)
    let certificates = LibraryPanel(title: Strings.AppMenuCertificatesTitleString, image: UIImage.templateImageNamed("menu-panel-Certificates"), color: UIColor.Photon.Magenta60)

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .fillEqually
        mainView.spacing = 10
        addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        [bookmarks, history, certificates].forEach { item in
            let view = LibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 :2
            view.button.backgroundColor = item.color
            view.button.setTitleColor(UIColor.theme.homePanel.topSiteDomain, for: .normal)
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            libraryButtons.append(view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        libraryButtons.forEach { button in
            button.title.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

open class PinnedSite: Site {
    let isPinnedSite = true

    init(site: Site) {
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.icon = site.icon
    }
}
