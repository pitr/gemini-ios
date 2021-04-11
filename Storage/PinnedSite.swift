import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger

class PinnedTopSite: Object {
    @objc dynamic public var url = ""
    @objc dynamic public var domain = ""
    @objc dynamic public var title = ""
    @objc dynamic public var pinnedAt = Date(timeIntervalSince1970: 1)
    public override class func primaryKey() -> String? {
        "url"
    }
}


extension DB {
    public func addPinnedTopSite(_ site: Site) -> Maybe<Void> {
        guard !isPinnedTopSite(site.url) else { return Maybe(success: ()) }

        let p = PinnedTopSite()
        p.url = site.url
        p.title = site.title
        p.domain = site.tileURL.normalizedHost ?? ""
        p.pinnedAt = Date()
        do {
            try self.realm.write {
                self.realm.add(p, update: .modified)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func isPinnedTopSite(_ url: String) -> Bool {
        return self.realm.object(ofType: PinnedTopSite.self, forPrimaryKey: url) != nil
    }

    public func removeFromPinnedTopSites(_ site: Site) -> Maybe<Void> {
        guard let p = self.realm.object(ofType: PinnedTopSite.self, forPrimaryKey: site.url) else { return Maybe(success: ()) }
        do {
            try self.realm.write {
                self.realm.delete(p)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func removeHostFromTopSites(_ host: String) -> Maybe<Void> {
        let p = self.realm.objects(PinnedTopSite.self).filter("domain = %@", host)
        do {
            try self.realm.write {
                self.realm.delete(p)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func getPinnedTopSites() -> [Site] {
        return self.realm.objects(PinnedTopSite.self).map { Site(url: $0.url, title: $0.title) }
    }
}
