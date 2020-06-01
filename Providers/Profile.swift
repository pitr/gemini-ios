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
    init() {
        let profileDirName = "profile.profile"

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
    var db: DB { get }
    var prefs: Prefs { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var certStore: CertStore { get }
    var recentlyClosedTabs: ClosedTabsStore { get }

    var isShutdown: Bool { get }

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _shutdown()

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _reopen()

    func cleanupHistoryIfNeeded()
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
    fileprivate let keychain: KeychainWrapper
    var isShutdown = false

    internal let files: FileAccessor

    let db: DB

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
    init(clear: Bool = false) {
        log.debug("Initing profile  on thread \(Thread.current).")
        self.files = ProfileFileAccessor()
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
        self.db = DB(filename: "browser.realm", files: files)
        self.db.setUp()

        if isNewProfile {
            log.info("New profile. Removing old Keychain/Prefs data.")
            KeychainWrapper.wipeKeychain()
            prefs.clearAll()
        }

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(onLocationChange), name: .OnLocationChange, object: nil)

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
    }

    func _shutdown() {
        log.debug("Shutting down profile.")
        isShutdown = true
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["historyType"] as? Int,
            let type = HistoryType(rawValue: v),
            let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
            let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                // We don't record a visit if no type was specified -- that means "ignore me".
                _ = db.addLocalVisit(url: url.absoluteString, title: title as String, type: type, visitedAt: Date())
            }
        } else {
            log.debug("Ignoring navigation.")
        }
    }

    deinit {
        log.debug("Deiniting profile.")
    }

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs()
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public func cleanupHistoryIfNeeded() {
        assert(Thread.isMainThread, "cleanupHistoryIfNeeded must run in main thread")
        db.cleanupHistoryIfNeeded()
    }

}
