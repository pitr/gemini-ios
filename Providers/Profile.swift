/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// IMPORTANT!: Please take into consideration when adding new imports to
// this file that it is utilized by external components besides the core
// application (i.e. App Extensions). Introducing new dependencies here
// may have unintended negative consequences for App Extensions such as
// increased startup times which may lead to termination by the OS.
import Shared
import Storage
import XCGLogger
import SwiftKeychainWrapper

// Import these dependencies ONLY for the main `Client` application target.
#if MOZ_TARGET_CLIENT
    import SwiftyJSON
#endif

private let log = Logger.syncLogger

public let ProfileRemoteTabsSyncDelay: TimeInterval = 0.1

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            log.error("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }

        super.init(rootPath: URL(fileURLWithPath: rootPath).appendingPathComponent(profileDirName).path)
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile: AnyObject {
    var places: RustPlaces { get }
    var prefs: Prefs { get }
    var queue: TabQueue { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: BrowserHistory & SyncableHistory & ResettableSyncStorage { get }
    var metadata: Metadata { get }
    var recommendations: HistoryRecommendations { get }
    var favicons: Favicons { get }
    var certStore: CertStore { get }
    var recentlyClosedTabs: ClosedTabsStore { get }
    var panelDataObservers: PanelDataObservers { get }

    var isShutdown: Bool { get }

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _shutdown()

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _reopen()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    func cleanupHistoryIfNeeded()

    @discardableResult func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>>
}

fileprivate let PrefKeyClientID = "PrefKeyClientID"
extension Profile {
    var clientID: String {
        let clientID: String
        if let id = prefs.stringForKey(PrefKeyClientID) {
            clientID = id
        } else {
            clientID = UUID().uuidString
            prefs.setString(clientID, forKey: PrefKeyClientID)
        }
        return clientID
    }
}

open class BrowserProfile: Profile {
    fileprivate let name: String
    fileprivate let keychain: KeychainWrapper
    var isShutdown = false

    internal let files: FileAccessor

    let db: BrowserDB

    private let loginsSaltKeychainKey = "sqlcipher.key.logins.salt"
    private let loginsUnlockKeychainKey = "sqlcipher.key.logins.db"
    private lazy var loginsKey: String = {
        if let secret = keychain.string(forKey: loginsUnlockKeychainKey) {
            return secret
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString
        keychain.set(secret, forKey: loginsUnlockKeychainKey, withAccessibility: .afterFirstUnlock)
        return secret
    }()

    /**
     * N.B., BrowserProfile is used from our extensions, often via a pattern like
     *
     *   BrowserProfile(…).foo.saveSomething(…)
     *
     * This can break if BrowserProfile's initializer does async work that
     * subsequently — and asynchronously — expects the profile to stick around:
     * see Bug 1218833. Be sure to only perform synchronous actions here.
     *
     * A SyncDelegate can be provided in this initializer, or once the profile is initialized.
     * However, if we provide it here, it's assumed that we're initializing it from the application.
     */
    init(localName: String, clear: Bool = false) {
        log.debug("Initing profile \(localName) on thread \(Thread.current).")
        self.name = localName
        self.files = ProfileFileAccessor(localName: localName)
        self.keychain = KeychainWrapper.sharedAppContainerKeychain

        if clear {
            do {
                // Remove the contents of the directory…
                try self.files.removeFilesInDirectory()
                // …then remove the directory itself.
                try self.files.remove("")
            } catch {
                log.info("Cannot clear profile: \(error)")
            }
        }

        // If the profile dir doesn't exist yet, this is first run (for this profile). The check is made here
        // since the DB handles will create new DBs under the new profile folder.
        let isNewProfile = !files.exists("")

        // Set up our database handles.
        self.db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)

        if isNewProfile {
            log.info("New profile. Removing old Keychain/Prefs data.")
            KeychainWrapper.wipeKeychain()
            prefs.clearAll()
        }

        // Log SQLite compile_options.
        // db.sqliteCompileOptions() >>== { compileOptions in
        //     log.debug("SQLite compile_options:\n\(compileOptions.joined(separator: "\n"))")
        // }

        // Set up logging from Rust.
        if !RustLog.shared.tryEnable({ (level, tag, message) -> Bool in
            let logString = "[RUST][\(tag ?? "no-tag")] \(message)"

            switch level {
            case .trace:
                if Logger.logPII {
                    log.verbose(logString)
                }
            case .debug:
                log.debug(logString)
            case .info:
                log.info(logString)
            case .warn:
                log.warning(logString)
            case .error:
                log.error(logString)
            }

            return true
        }) {
            log.error("ERROR: Unable to enable logging from Rust")
        }

        // By default, filter logging from Rust below `.info` level.
        try? RustLog.shared.setLevelFilter(filter: .info)

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(onLocationChange), name: .OnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onPageMetadataFetched), name: .OnPageMetadataFetched, object: nil)

        // Always start by needing invalidation.
        // This is the same as self.history.setTopSitesNeedsInvalidation, but without the
        // side-effect of instantiating SQLiteHistory (and thus BrowserDB) on the main thread.
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)

        // Remove the default homepage. This does not change the user's preference,
        // just the behaviour when there is no homepage.
        prefs.removeObjectForKey(PrefsKeys.KeyDefaultHomePageURL)

        // Create the "Downloads" folder in the documents directory.
        if let downloadsPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads").path {
            try? FileManager.default.createDirectory(atPath: downloadsPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func _reopen() {
        log.debug("Reopening profile.")
        isShutdown = false

        if !places.isOpen {
            places.migrateBookmarksIfNeeded(fromBrowserDB: db)
        }

        db.reopenIfClosed()
        _ = places.reopenIfClosed()
    }

    func _shutdown() {
        log.debug("Shutting down profile.")
        isShutdown = true

        db.forceClose()
        _ = places.forceClose()
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["visitType"] as? Int,
           let visitType = VisitType(rawValue: v),
           let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
           let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                // We don't record a visit if no type was specified -- that means "ignore me".
                let site = Site(url: url.absoluteString, title: title as String)
                let visit = SiteVisit(site: site, date: Date.nowMicroseconds(), type: visitType)
                history.addLocalVisit(visit)
            }

            history.setTopSitesNeedsInvalidation()
        } else {
            log.debug("Ignoring navigation.")
        }
    }

    @objc
    func onPageMetadataFetched(notification: NSNotification) {
        let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? true
        guard !isPrivate else {
            log.debug("Private mode - Ignoring page metadata.")
            return
        }
        guard let pageURL = notification.userInfo?["tabURL"] as? URL,
              let pageMetadata = notification.userInfo?["pageMetadata"] as? PageMetadata else {
            log.debug("Metadata notification doesn't contain any metadata!")
            return
        }
        let defaultMetadataTTL: UInt64 = 3 * 24 * 60 * 60 * 1000 // 3 days for the metadata to live
        self.metadata.storeMetadata(pageMetadata, forPageURL: pageURL, expireAt: defaultMetadataTTL + Date.now())
    }

    deinit {
        log.debug("Deiniting profile \(self.localName()).")
    }

    func localName() -> String {
        return name
    }

    lazy var queue: TabQueue = {
        withExtendedLifetime(self.history) {
            return SQLiteQueue(db: self.db)
        }
    }()

    /**
     * Favicons, history, and tabs are all stored in one intermeshed
     * collection of tables.
     *
     * Any other class that needs to access any one of these should ensure
     * that this is initialized first.
     */
    fileprivate lazy var legacyPlaces: BrowserHistory & Favicons & SyncableHistory & ResettableSyncStorage & HistoryRecommendations  = {
        return SQLiteHistory(db: self.db, prefs: self.prefs)
    }()

    var favicons: Favicons {
        return self.legacyPlaces
    }

    var history: BrowserHistory & SyncableHistory & ResettableSyncStorage {
        return self.legacyPlaces
    }

    lazy var panelDataObservers: PanelDataObservers = {
        return PanelDataObservers(profile: self)
    }()

    lazy var metadata: Metadata = {
        return SQLiteMetadata(db: self.db)
    }()

    var recommendations: HistoryRecommendations {
        return self.legacyPlaces
    }

    lazy var placesDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("places.db").path

    lazy var places = RustPlaces(databasePath: placesDbPath)

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs(prefix: self.localName())
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var remoteClientsAndTabs: RemoteClientsAndTabs & ResettableSyncStorage & AccountRemovalDelegate & RemoteDevices = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public func cleanupHistoryIfNeeded() {
        recommendations.cleanupHistoryIfNeeded()
    }

    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.remoteClientsAndTabs.insertOrUpdateTabs(tabs)
    }
}
