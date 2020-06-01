import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger

public class TabQueue: Object {
    @objc dynamic public var id = Bytes.generateGUID()
    @objc dynamic public var url = ""
    @objc dynamic public var title: String?
    public override class func primaryKey() -> String? {
        "id"
    }
}

extension DB {
    public func addToQueue(_ tab: ShareItem) -> Maybe<Void> {
        let q = TabQueue()
        q.url = tab.url
        q.title = tab.title
        do {
            try realm.write {
                realm.add(q)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func getQueuedTabs() -> Results<TabQueue> {
        return realm.objects(TabQueue.self)
    }

    public func clearQueuedTabs() -> Maybe<Void> {
        let q = realm.objects(TabQueue.self)
        do {
            try realm.write {
                realm.delete(q)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }
}
