import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger


// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
public enum HistoryType: Int {
    case unknown = 0
    case link = 1
    case typed = 2
    case bookmark = 3
    case embed = 4
    case permanentRedirect = 5
    case temporaryRedirect = 6
    case download = 7
    case framedLink = 8
}

public class History: Object {
    @objc dynamic public var id = Bytes.generateGUID()
    @objc dynamic public var url = ""
    @objc dynamic public var title = ""
    @objc dynamic var _type = 0
    public var type: HistoryType {
        HistoryType.init(rawValue: _type)!
    }
    @objc dynamic public var visitedAt = Date(timeIntervalSince1970: 1)
    public override class func primaryKey() -> String? {
        "id"
    }
}

fileprivate func getDate(dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.year, .month, .day], from: Date())
    let today = calendar.date(from: components)!
    return calendar.date(byAdding: .day, value: dayOffset, to: today)!
}

fileprivate let ignoredSchemes = ["about"]
public func isIgnoredURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }

    return ignoredSchemes.contains(scheme) || url.host == "localhost"
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url) {
        return isIgnoredURL(url)
    }

    return false
}

fileprivate let MaxHistoryRowCount = 1000

extension DB {
    public func getSitesByLastVisit() -> [Results<History>] {
        let todayTimestamp = getDate(dayOffset: 0)
        let yesterdayTimestamp = getDate(dayOffset: -1)
        let lastWeekTimestamp = getDate(dayOffset: -7)

        let q = self.realm.objects(History.self).sorted(byKeyPath: "visitedAt", ascending: false)

        return [
            q.filter("visitedAt > %@", todayTimestamp), // today
            q.filter("visitedAt > %@ AND visitedAt <= %@", yesterdayTimestamp, todayTimestamp), // yesterday
            q.filter("visitedAt > %@ AND visitedAt <= %@", lastWeekTimestamp, yesterdayTimestamp), // last week
            q.filter("visitedAt <= %@", lastWeekTimestamp), // last month
        ]
    }

    public func addLocalVisit(url: String, title: String, type: HistoryType, visitedAt: Date) -> Maybe<Void> {
        let h = History()
        h.url = url
        h.title = title
        h._type = type.rawValue
        h.visitedAt = visitedAt
        do {
            try self.realm.write {
                self.realm.add(h)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func searchHistory(query: String, limit: Int) -> [Site] {
        let result = self.realm.objects(History.self).filter("url CONTAINS %@ OR title CONTAINS %@", query, query)
        var sites = [Site]()
        var count = 0
        var it = result.makeIterator()
        while let h = it.next() {
            sites.append(Site(url: h.url, title: h.title))
            count += 1
            if count >= limit { break }
        }
        return sites
    }

    public func getTopSitesWithLimit(_ limit: Int) -> [Site] {
        var it = self.realm
            .objects(History.self)
            .groupBy({ $0.url }, transformer: { Site(url: $0.url, title: $0.title) })
            .sorted { $0.value.count > $1.value.count }
            .makeIterator()
        var sites = [Site]()
        var count = 0
        while let ss = it.next() {
            guard let s = ss.value.first else { continue }
            sites.append(s)
            count += 1
            if count >= limit { break }
        }
        return sites
    }

    public func clearHistory() {
        let history = self.realm.objects(History.self)
        try! self.realm.write {
            self.realm.delete(history)
        }
    }

    public func removeHistoryFromDate(_ date: Date) {
        let history = self.realm.objects(History.self).filter("visitedAt > %@", date)
        try! self.realm.write {
            self.realm.delete(history)
        }
    }

    public func removeHistoryForURL(_ url: String) {
        let history = self.realm.objects(History.self).filter("url = %@", url)
        try! self.realm.write {
            self.realm.delete(history)
        }
    }

    public func cleanupHistoryIfNeeded() {
        let q = self.realm.objects(History.self).sorted(byKeyPath: "visitedAt", ascending: false)
        guard q.count > MaxHistoryRowCount else { return }

        let date = q[MaxHistoryRowCount-1].visitedAt

        let toDelete = self.realm.objects(History.self).filter("visitedAt < %@", date)
        try! self.realm.write {
            self.realm.delete(toDelete)
        }
    }
}
