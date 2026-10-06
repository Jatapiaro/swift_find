import ArgumentParser
import Foundation

func findFilesInPath(path: String?, recursively: Bool = false) -> [String] {
  let fm: FileManager = FileManager.default
  let path: URL = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
  var results: [String] = []
  var options: FileManager.DirectoryEnumerationOptions = []
  if !recursively {
    options.insert(.skipsSubdirectoryDescendants)
  }

  if let enumerator: FileManager.DirectoryEnumerator = fm.enumerator(
    at: path, includingPropertiesForKeys: nil, options: options)
  {
    for case let fileURL as URL in enumerator {
      if !fileURL.hasDirectoryPath {
        results.append(fileURL.path)
      }
    }
  }

  return results
}

@main
struct SwiftFind: ParsableCommand {
  @Argument(help: "The word to search.")
  var word: String
  @Argument(help: "The path to scan files for the given word.")
  var path: String? = nil

  mutating func run() throws {
    let res = findFilesInPath(path: path, recursively: true)
    for r in res {
        print(r)
    }
  }
}
