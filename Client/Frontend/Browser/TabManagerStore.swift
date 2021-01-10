/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger
class TabManagerStore {
    fileprivate var lockedForReading = false
    fileprivate let imageStore: DiskImageStore?
    fileprivate var fileManager = FileManager.default
    fileprivate let serialQueue = DispatchQueue(label: "tab-manager-write-queue")
    fileprivate var writeOperation = DispatchWorkItem {}

    // Init this at startup with the tabs on disk, and then on each save, update the in-memory tab state.
    fileprivate lazy var archivedStartupTabs = { return tabsToRestore() }()

    init(imageStore: DiskImageStore?, _ fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
        self.imageStore = imageStore
    }

    var isRestoringTabs: Bool {
        return lockedForReading
    }

    var hasTabsToRestoreAtStartup: Bool {
        return archivedStartupTabs.count > 0
    }

    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = fileManager.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }

    fileprivate func tabsToRestore() -> [SavedTab] {
        guard let tabStateArchivePath = tabsStateArchivePath(),
            fileManager.fileExists(atPath: tabStateArchivePath),
            let tabData = try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)) else {
                return [SavedTab]()
        }

        let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            return [SavedTab]()
        }
        return tabs
    }

    fileprivate func prepareSavedTabs(fromTabs tabs: [Tab], selectedTab: Tab?) -> [SavedTab]? {
        var savedTabs = [SavedTab]()
        var savedUUIDs = Set<String>()
        for tab in tabs {
            if let savedTab = SavedTab(tab: tab, isSelected: tab === selectedTab) {
                savedTabs.append(savedTab)

                if let screenshot = tab.screenshot,
                    let screenshotUUID = tab.screenshotUUID {
                    savedUUIDs.insert(screenshotUUID.uuidString)
                    imageStore?.put(screenshotUUID.uuidString, image: screenshot)
                }
            }
        }
        // Clean up any screenshots that are no longer associated with a tab.
        _ = imageStore?.clearExcluding(savedUUIDs)
        return savedTabs.isEmpty ? nil : savedTabs
    }

    // Async write of the tab state. In most cases, code doesn't care about performing an operation
    // after this completes. Deferred completion is called always, regardless of Data.write return value.
    // Write failures (i.e. due to read locks) are considered inconsequential, as preserveTabs will be called frequently.
    @discardableResult func preserveTabs(_ tabs: [Tab], selectedTab: Tab?) -> Success {
        assert(Thread.isMainThread)
        guard let savedTabs = prepareSavedTabs(fromTabs: tabs, selectedTab: selectedTab),
            let path = tabsStateArchivePath() else {
                clearArchive()
                return succeed()
        }

        writeOperation.cancel()

        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        archiver.encode(savedTabs, forKey: "tabs")
        archiver.finishEncoding()

        let result = Success()
        writeOperation = DispatchWorkItem {
            let written = tabStateData.write(toFile: path, atomically: true)
            log.debug("PreserveTabs write ok: \(written)") // Ignore write failure (could be restoring).
            result.fill(Maybe(success: ()))
        }

        // Delay by 100ms to debounce repeated calls to preserveTabs in quick succession.
        // Notice above that a repeated 'preserveTabs' call will 'cancel()' a pending write operation.
        serialQueue.asyncAfter(deadline: .now() + 0.100, execute: writeOperation)

        return result
    }

    func restoreStartupTabs(tabManager: TabManager) -> Tab? {
        let selectedTab = restoreTabs(savedTabs: archivedStartupTabs, tabManager: tabManager)
        archivedStartupTabs.removeAll()
        return selectedTab
    }

    func restoreTabs(savedTabs: [SavedTab], tabManager: TabManager) -> Tab? {
        assertIsMainThread("Restoration is a main-only operation")
        guard !lockedForReading, savedTabs.count > 0 else { return nil }
        lockedForReading = true
        defer {
            lockedForReading = false
        }

        var tabToSelect: Tab?
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            var tab = tabManager.addTab(flushToDisk: false, zombie: true)
            tab = savedTab.configureSavedTabUsing(tab, imageStore: imageStore)

            if savedTab.isSelected {
                tabToSelect = tab
            }
        }

        if tabToSelect == nil {
            tabToSelect = tabManager.tabs.first
        }

        return tabToSelect
    }

    func clearArchive() {
        if let path = tabsStateArchivePath() {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
