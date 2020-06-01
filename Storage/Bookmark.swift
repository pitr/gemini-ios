import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger

public enum BookmarkNodeType: Int {
    case bookmark = 1
    case folder = 2
    case separator = 3
}

public class Bookmark: Object {
    public static let RootGUID = "__root"

    @objc dynamic public var id = Bytes.generateGUID()
    @objc dynamic var _type = 0
    public var type: BookmarkNodeType {
        BookmarkNodeType.init(rawValue: _type)!
    }
    public let children = List<Bookmark>()
    public let parent = LinkingObjects(fromType: Bookmark.self, property: "children")
    @objc dynamic public var url = ""
    @objc dynamic public var title = ""
    @objc dynamic public var createdAt = Date(timeIntervalSince1970: 1)
    public override class func primaryKey() -> String? {
        "id"
    }
    public var isRoot: Bool {
        parent.count == 0
    }

    convenience init(type: BookmarkNodeType) {
        self.init()
        self._type  = type.rawValue
        self.createdAt = Date()
    }
}

extension DB {

    public func deleteBookmarkNode(_ b: Bookmark) {
        b.children.forEach { (child) in
            deleteBookmarkNode(child)
        }
        try! self.realm.write {
            self.realm.delete(b)
        }
    }

    public func deleteBookmarksWithURL(url: String) -> Maybe<Void> {
        let b = self.realm.objects(Bookmark.self).filter("url = %@", url)
        do {
            try self.realm.write {
                self.realm.delete(b)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func createBookmark(parentGUID: GUID, url: String, title: String?, position: Int? = nil) -> Maybe<GUID> {
        guard let parent = getBookmark(guid: parentGUID) else { return Maybe(failure: RecordNotFoundError()) }

        let b = Bookmark(type: .bookmark)
        b.url = url
        b.title = title ?? ""
        do {
            try self.realm.write {
                if let position = position {
                    parent.children.insert(b, at: position)
                } else {
                    parent.children.append(b)
                }
            }
            return Maybe(success: b.id)
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func createSeparator(parentGUID: GUID, position: Int) -> Maybe<GUID> {
        guard let parent = getBookmark(guid: parentGUID) else { return Maybe(failure: RecordNotFoundError()) }

        let b = Bookmark(type: .separator)
        do {
            try self.realm.write {
                parent.children.insert(b, at: position)
            }
            return Maybe(success: b.id)
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func createRootFolder(guid: GUID) -> Maybe<Void> {
        let b = Bookmark(type: .folder)
        b.id = guid
        do {
            try self.realm.write {
                self.realm.add(b)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func createFolder(parentGUID: GUID, title: String, position: Int? = nil) -> Maybe<GUID> {
        guard let parent = getBookmark(guid: parentGUID) else { return Maybe(failure: RecordNotFoundError()) }

        let b = Bookmark(type: .folder)
        b.title = title
        do {
            try self.realm.write {
                if let position = position {
                    parent.children.insert(b, at: position)
                } else {
                    parent.children.append(b)
                }
            }
            return Maybe(success: b.id)
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func updateBookmarkNode(guid: GUID, parentGUID: GUID, title: String?, url: String? = "") -> Maybe<GUID> {
        guard let b = getBookmark(guid: guid) else { return Maybe(failure: RecordNotFoundError()) }

        do {
            try self.realm.write {
                b.title = title ?? ""
                b.url = url ?? ""
            }
            guard let parent = b.parent.first else { return Maybe(failure: RecordNotFoundError()) }
            if parent.id != parentGUID {
                guard let newParent = getBookmark(guid: parentGUID), let ix = parent.children.index(of: b)
                    else { return Maybe(failure: RecordNotFoundError()) }
                try self.realm.write {
                    parent.children.remove(at: ix)
                    newParent.children.insert(b, at: 0)
                }
            }
            return Maybe(success: guid)
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func getBookmark(guid: GUID) -> Bookmark? {
        return self.realm.object(ofType: Bookmark.self, forPrimaryKey: guid)
    }

    public func getBookmarksWithURL(url: String) -> Results<Bookmark> {
        return self.realm.objects(Bookmark.self).filter("url = %@", url)
    }

    public func isBookmarked(url: String) -> Bool {
        return !self.realm.objects(Bookmark.self).filter("url = %@", url).isEmpty
    }

    public func getRecentBookmarks() -> Results<Bookmark> {
        return self.realm.objects(Bookmark.self)
            .filter("id != %@ and _type = %@", Bookmark.RootGUID, BookmarkNodeType.bookmark.rawValue)
            .sorted(byKeyPath: "createdAt", ascending: false)
    }

    public func searchBookmarks(query: String, limit: Int) -> [Site] {
        let result = self.realm.objects(Bookmark.self)
            .filter("_type = %@ and (url CONTAINS %@ OR title CONTAINS %@)", BookmarkNodeType.bookmark.rawValue, query, query)
        var sites = [Site]()
        var count = 0
        var it = result.makeIterator()
        while let b = it.next() {
            sites.append(Site(url: b.url, title: b.title))
            count += 1
            if count >= limit { break }
        }
        return sites
    }
}
