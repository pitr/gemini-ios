/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger
import RealmSwift

private let log = Logger.browserLogger

private let BookmarkNodeCellIdentifier = "BookmarkNodeCellIdentifier"
private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorCellIdentifier"
private let BookmarkSectionHeaderIdentifier = "BookmarkSectionHeaderIdentifier"

private struct BookmarksPanelUX {
    static let FolderIconSize = CGSize(width: 20, height: 20)
    static let RowFlashDelay: TimeInterval = 0.4
}

fileprivate class SeparatorTableViewCell: OneLineTableViewCell {
    override func applyTheme() {
        super.applyTheme()

        backgroundColor = UIColor.theme.tableView.headerBackground
    }
}

class BookmarksPanel: SiteTableViewController, LibraryPanel {
    enum BookmarksSection: Int, CaseIterable {
        case bookmarks
        case recent
    }

    var libraryPanelDelegate: LibraryPanelDelegate?

    var editBarButtonItem: UIBarButtonItem!
    var doneBarButtonItem: UIBarButtonItem!
    var newBarButtonItem: UIBarButtonItem!

    var bookmarkFolder: Bookmark
    var recentBookmarks: Results<Bookmark>

    fileprivate var flashLastRowOnNextReload = false

    fileprivate lazy var bookmarkFolderIconNormal = UIImage(named: "bookmarkFolder")?.createScaled(BookmarksPanelUX.FolderIconSize).tinted(withColor: UIColor.Photon.Grey90)
    fileprivate lazy var bookmarkFolderIconDark = UIImage(named: "bookmarkFolder")?.createScaled(BookmarksPanelUX.FolderIconSize).tinted(withColor: UIColor.Photon.Grey10)

    init(profile: Profile, bookmarkFolderGUID: GUID = Bookmark.RootGUID) {
        self.bookmarkFolder = profile.db.getBookmark(guid: bookmarkFolderGUID)!
        self.recentBookmarks = profile.db.getRecentBookmarks()

        super.init(profile: profile)

        [ Notification.Name.DynamicFontChanged ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil)
        }

        self.tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: BookmarkNodeCellIdentifier)
        self.tableView.register(SeparatorTableViewCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.register(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkSectionHeaderIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableViewLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTableView))
        tableView.addGestureRecognizer(tableViewLongPressRecognizer)
        tableView.accessibilityIdentifier = "Bookmarks List"
        tableView.allowsSelectionDuringEditing = true

        self.editBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit) { _ in
            self.enableEditMode()
        }

        self.doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done) { _ in
            self.disableEditMode()
        }

        self.newBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add) { _ in
            let newBookmark = PhotonActionSheetItem(title: Strings.BookmarksNewBookmark, iconString: "action_bookmark", handler: { _, _ in
                let detailController = BookmarkDetailPanel(profile: self.profile, withNewBookmarkNodeType: .bookmark, parentBookmarkFolder: self.bookmarkFolder)
                self.navigationController?.pushViewController(detailController, animated: true)
            })

            let newFolder = PhotonActionSheetItem(title: Strings.BookmarksNewFolder, iconString: "bookmarkFolder", handler: { _, _ in
                let detailController = BookmarkDetailPanel(profile: self.profile, withNewBookmarkNodeType: .folder, parentBookmarkFolder: self.bookmarkFolder)
                self.navigationController?.pushViewController(detailController, animated: true)
            })

            let newSeparator = PhotonActionSheetItem(title: Strings.BookmarksNewSeparator, iconString: "nav-menu", handler: { _, _ in
                let centerVisibleRow = self.centerVisibleRow()

                if self.profile.db.createSeparator(parentGUID: self.bookmarkFolder.id, position: centerVisibleRow).isSuccess {
                    let indexPath = IndexPath(row: centerVisibleRow, section: BookmarksSection.bookmarks.rawValue)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    self.tableView.endUpdates()
                    self.flashRow(at: indexPath)
                }
            })

            let sheet = PhotonActionSheet(actions: [[newBookmark, newFolder, newSeparator]])
            sheet.modalPresentationStyle = .overFullScreen
            sheet.modalTransitionStyle = .crossDissolve
            self.present(sheet, animated: true)
        }

        navigationItem.rightBarButtonItem = editBarButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupBackButtonGestureRecognizer()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if tableView.isEditing {
            disableEditMode()
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func applyTheme() {
        super.applyTheme()

        if let current = navigationController?.visibleViewController as? Themeable, current !== self {
            current.applyTheme()
        }
    }

    override func reloadData() {
        self.tableView.reloadData()

        if self.flashLastRowOnNextReload {
            self.flashLastRowOnNextReload = false

            let lastIndexPath = IndexPath(row: self.bookmarkFolder.children.count - 1, section: BookmarksSection.bookmarks.rawValue)
            DispatchQueue.main.asyncAfter(deadline: .now() + BookmarksPanelUX.RowFlashDelay) {
                self.flashRow(at: lastIndexPath)
            }
        }
    }
    
    fileprivate func enableEditMode() {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.leftBarButtonItem = self.newBarButtonItem
        self.navigationItem.rightBarButtonItem = self.doneBarButtonItem
    }
    
    fileprivate func disableEditMode() {
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = self.editBarButtonItem
        self.setupBackButtonGestureRecognizer()
    }

    fileprivate func setupBackButtonGestureRecognizer() {
        if let backButtonView = self.backButtonView() {
            let backButtonViewLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBackButtonView))
            backButtonView.addGestureRecognizer(backButtonViewLongPressRecognizer)
        }
    }

    fileprivate func backButtonView() -> UIView? {
        let navigationBarContentView = navigationController?.navigationBar.subviews.find({ $0.description.starts(with: "<_UINavigationBarContentView:") })
        return navigationBarContentView?.subviews.find({ $0.description.starts(with: "<_UIButtonBarButton:") })
    }

    fileprivate func centerVisibleRow() -> Int {
        let visibleCells = tableView.visibleCells
        if let middleCell = visibleCells[safe: visibleCells.count / 2],
            let middleIndexPath = tableView.indexPath(for: middleCell) {
            return middleIndexPath.row
        }

        return bookmarkFolder.children.count
    }

    fileprivate func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = indexPath.section == BookmarksSection.bookmarks.rawValue ? bookmarkFolder.children[safe: indexPath.row] : recentBookmarks[safe: indexPath.row] else {
            return
        }

        func doDelete() {
            // Perform the delete asynchronously even though we update the
            // table view data source immediately for responsiveness.
            profile.db.deleteBookmarkNode(bookmarkNode)

            tableView.reloadData()
        }

        // If this node is a folder and it is not empty, we need
        // to prompt the user before deleting.
        if bookmarkNode.type == .folder,
            !bookmarkFolder.children.isEmpty {
            let alertController = UIAlertController(title: Strings.BookmarksDeleteFolderWarningTitle, message: Strings.BookmarksDeleteFolderWarningDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Strings.BookmarksDeleteFolderCancelButtonLabel, style: .cancel))
            alertController.addAction(UIAlertAction(title: Strings.BookmarksDeleteFolderDeleteButtonLabel, style: .destructive) { (action) in
                doDelete()
            })
            present(alertController, animated: true, completion: nil)
            return
        }

        doDelete()
    }

    fileprivate func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        return indexPath.section < numberOfSections(in: tableView) &&
            indexPath.row < tableView(tableView, numberOfRowsInSection: indexPath.section)
    }

    fileprivate func flashRow(at indexPath: IndexPath) {
        guard indexPathIsValid(indexPath) else {
            return
        }

        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)

        DispatchQueue.main.asyncAfter(deadline: .now() + BookmarksPanelUX.RowFlashDelay) {
            if self.indexPathIsValid(indexPath) {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    func didAddBookmarkNode() {
        flashLastRowOnNextReload = true
    }

    @objc fileprivate func didLongPressTableView(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard longPressGestureRecognizer.state == .began, let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }

        presentContextMenu(for: indexPath)
    }

    @objc fileprivate func didLongPressBackButtonView(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        navigationController?.popToRootViewController(animated: true)
    }

    @objc fileprivate func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            reloadData()
        default:
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let node: Bookmark?

        if indexPath.section == BookmarksSection.recent.rawValue {
            node = recentBookmarks[safe: indexPath.row]
        } else {
            node = bookmarkFolder.children[safe: indexPath.row]
        }

        guard let bookmarkNode = node else {
            return
        }

        guard !tableView.isEditing else {
            if bookmarkNode.type != .separator {
                let detailController = BookmarkDetailPanel(profile: profile, bookmarkNode: bookmarkNode, parentBookmarkFolder: bookmarkFolder)
                navigationController?.pushViewController(detailController, animated: true)
            }
            return
        }

        switch bookmarkNode.type {
        case .folder:
            let nextController = BookmarksPanel(profile: profile, bookmarkFolderGUID: bookmarkNode.id)
            if bookmarkNode.isRoot {
                nextController.title = Strings.AllBookmarksTitle
            } else {
                nextController.title = bookmarkNode.title
            }
            nextController.libraryPanelDelegate = libraryPanelDelegate
            navigationController?.pushViewController(nextController, animated: true)
        case .bookmark:
            libraryPanelDelegate?.libraryPanel(didSelectURLString: bookmarkNode.url, historyType: .bookmark)
        case .separator:
            return // Likely a separator was selected so do nothing.
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == BookmarksSection.recent.rawValue ? min(recentBookmarks.count, 20) : bookmarkFolder.children.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if bookmarkFolder.id == Bookmark.RootGUID {
            return 2
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarkNode = indexPath.section == BookmarksSection.recent.rawValue ? recentBookmarks[safe: indexPath.row] : bookmarkFolder.children[safe: indexPath.row] else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        switch bookmarkNode.type {
        case .folder:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkNodeCellIdentifier, for: indexPath)
            if bookmarkNode.isRoot {
                cell.textLabel?.text = Strings.AllBookmarksTitle
            } else {
                cell.textLabel?.text = bookmarkNode.title
            }

            cell.imageView?.image = ThemeManager.instance.currentName == .dark ? bookmarkFolderIconDark : bookmarkFolderIconNormal
            cell.imageView?.contentMode = .center
            cell.accessoryType = .disclosureIndicator
            cell.editingAccessoryType = .disclosureIndicator
            return cell
        case .bookmark:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkNodeCellIdentifier, for: indexPath)
            if bookmarkNode.title.isEmpty {
                cell.textLabel?.text = bookmarkNode.url
            } else {
                cell.textLabel?.text = bookmarkNode.title
            }

            cell.imageView?.image = nil

            if let url = bookmarkNode.url.asURL {
                cell.imageView?.image = FaviconFetcher.letter(forUrl: url)
            } else {
                cell.imageView?.image = FaviconFetcher.defaultFavicon
            }
            cell.imageView?.contentMode = .scaleAspectFill
            cell.accessoryType = .none
            cell.editingAccessoryType = .disclosureIndicator
            return cell
        case .separator:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkSeparatorCellIdentifier, for: indexPath)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == BookmarksSection.recent.rawValue, !recentBookmarks.isEmpty,
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BookmarkSectionHeaderIdentifier) as? SiteTableViewHeader else {
            return nil
        }

        headerView.titleLabel.text = Strings.RecentlyBookmarkedTitle
        headerView.showBorder(for: .top, true)
        headerView.showBorder(for: .bottom, true)

        return headerView
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? ThemedTableSectionHeaderFooterView else {
            return
        }

        headerView.applyTheme()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == BookmarksSection.recent.rawValue && !recentBookmarks.isEmpty ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        try! bookmarkFolder.realm?.write {
            bookmarkFolder.children.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: Strings.BookmarksPanelDeleteTableAction, handler: { (action, indexPath) in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
        })

        return [delete]
    }
}

// MARK: LibraryPanelContextMenu

extension BookmarksPanel: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else {
            return
        }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let bookmarkNode = indexPath.section == BookmarksSection.recent.rawValue ? recentBookmarks[safe: indexPath.row] : bookmarkFolder.children[safe: indexPath.row],
            bookmarkNode.type == .bookmark else {
            return nil
        }

        return Site(url: bookmarkNode.url, title: bookmarkNode.title, bookmarked: true, guid: bookmarkNode.id)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else {
            return nil
        }

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { _, _ in
            _ = self.profile.db.addPinnedTopSite(site)
        })
        actions.append(pinTopSite)

        let removeAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { _, _ in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
        })
        actions.append(removeAction)

        return actions
    }
}
