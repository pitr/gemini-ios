import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger

public class Certificate: Object {
    @objc dynamic public var id = Bytes.generateGUID()
    @objc dynamic public var host = ""
    @objc dynamic public var name = ""
    @objc dynamic public var isActive = false
    @objc dynamic public var data = Data()
    @objc dynamic public var fingerprint = ""
    @objc dynamic var _type = 0
    @objc dynamic public var createdAt = Date(timeIntervalSince1970: 1)
    @objc dynamic public var lastUsedAt = Date(timeIntervalSince1970: 1)
    public override class func primaryKey() -> String? {
        "id"
    }
}

extension DB {
    public func getActiveCertificate(host: String) -> Certificate? {
        let q = self.realm.objects(Certificate.self)
            .filter("host = %@ and isActive = true", host)
            .sorted(byKeyPath: "lastUsedAt", ascending: false)
        return q[safe: 0]
    }

    public func addAndActivateCertificate(host: String, name: String, data: Data, fingerprint: String) -> Maybe<Void> {
        let result = deactivateCertificatesFor(host: host)
        if result.isFailure {
            return result
        }

        let c = Certificate()
        c.host = host
        c.name = name
        c.isActive = true
        c.data = data
        c.fingerprint = fingerprint
        c.createdAt = Date()
        c.lastUsedAt = Date()
        do {
            try self.realm.write {
                self.realm.add(c)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func activateCertificate(_ c: Certificate) -> Maybe<Void> {
        let result = deactivateCertificatesFor(host: c.host)
        if result.isFailure {
            return result
        }

        do {
            try self.realm.write {
                c.isActive = true
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func deactivateCertificatesFor(host: String) -> Maybe<Void> {
        do {
            let q = self.realm.objects(Certificate.self).filter("host = %@ and isActive = true", host)
            try self.realm.write {
                q.setValue(false, forKey: "isActive")
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func recordVisit(for c: Certificate) -> Maybe<Void> {
        do {
            try self.realm.write {
                c.lastUsedAt = Date()
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func deleteCertificate(_ c: Certificate) -> Maybe<Void> {
        do {
            try self.realm.write {
                self.realm.delete(c)
            }
            return Maybe(success: ())
        } catch let error as NSError {
            return Maybe(failure: error)
        }
    }

    public func getAllCertificatesByHost() -> [[Certificate]] {
        let values = self.realm.objects(Certificate.self)
            .sorted(byKeyPath: "lastUsedAt", ascending: false)
            .groupBy({ $0.host }, transformer: { $0 })
            .values
        return Array(values)
    }

    public func getAllCertificatesFor(host: String) -> Results<Certificate> {
        return self.realm.objects(Certificate.self)
            .filter("host = %@", host)
            .sorted(byKeyPath: "lastUsedAt", ascending: false)
    }
}
