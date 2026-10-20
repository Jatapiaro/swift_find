import CSQLite
import Foundation

enum DBError: Error {
    case open(String)
    case sql(String)
}

actor Database {
    private let handle: OpaquePointer

    init(file: URL) throws {
        var h: OpaquePointer?
        
        let result: Int32 = file.withUnsafeFileSystemRepresentation { path in
            sqlite3_open(path, &h)
        }
        
        guard result == SQLITE_OK, let h: OpaquePointer else {
            let message = h.map { String(cString: sqlite3_errmsg($0)) } ?? ""
            sqlite3_close(h)
            throw DBError.open("\(file.path): \(message)")
        }

        handle = h
    }

    isolated deinit {
        sqlite3_close(handle)
    }
}