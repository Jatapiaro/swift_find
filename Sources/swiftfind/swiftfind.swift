import ArgumentParser
import Foundation

func findFilesInPath(path: String?) -> [String] {
    let fm = FileManager.default
    let path = path ?? fm.currentDirectoryPath

    do {
        let result = try fm.contentsOfDirectory(atPath: path)
        return result
    } catch {
        return []
    }
}

@main
struct SwiftFind: ParsableCommand {
    @Argument(help: "The word to search.")
    var word: String
    @Argument(help: "The path to scan files for the given word.")
    var path: String? = nil

    mutating func run() throws {
        print(findFilesInPath(path: path))
    }
}
