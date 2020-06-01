import Shared
import XCGLogger
import RealmSwift

private let log = Logger.syncLogger

public class RecordNotFoundError : MaybeErrorType {
    public var description: String {
        return "Record Not Found"
    }
}

public class DB {
    let realm: Realm

    public init(filename: String, files: FileAccessor) {
        var config = Realm.Configuration()
        config.schemaVersion = 0
        config.migrationBlock = { (migration, oldSchemaVersion) in
            log.info("Migrating DB from \(oldSchemaVersion) to \(migration.newSchema)")
        }

        config.fileURL = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename)

        Realm.Configuration.defaultConfiguration = config

        self.realm = try! Realm()
    }

    public func setUp() {
        guard realm.isEmpty else { return }

        if let err = createRootFolder(guid: Bookmark.RootGUID).failureValue {
            log.error(err)
        }
    }
}
