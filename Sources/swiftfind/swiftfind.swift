import ArgumentParser
import Foundation

func findFilesInPath(path: String?, excluding: Set<String>?, recursively: Bool = false) -> [String]
{
  let fm: FileManager = FileManager.default
  let path: URL = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
  let resourceKeys: Set<URLResourceKey> = Set([.isDirectoryKey, .nameKey])

  var results: [String] = []
  var options: FileManager.DirectoryEnumerationOptions = []
  if !recursively {
    options.insert(.skipsSubdirectoryDescendants)
  }

  if let enumerator: FileManager.DirectoryEnumerator = fm.enumerator(
    at: path, includingPropertiesForKeys: nil, options: options)
  {
    for case let fileURL as URL in enumerator {
      guard let values = try? fileURL.resourceValues(forKeys: resourceKeys) else {
        continue
      }

      if values.isDirectory == true {
        if let name = values.name, excluding?.contains(name) == true {
          enumerator.skipDescendants()
        }
        continue
      }

      results.append(fileURL.path)
    }
  }

  return results
}

func findWordInFile(file: String, word: String) async -> [Int: String] {
  var results: [Int: String] = [Int: String]()
  var lineCounter: Int = 0
  guard let fileHandle: FileHandle = FileHandle(forReadingAtPath: file) else {
    return results
  }
  defer { try? fileHandle.close() }

  func isWordInLine(line: String, word: String, ignoreCase: Bool = true) -> Bool {
    return line.lowercased().contains(word.lowercased())
  }

// FileHandle.bytes is not available on Windows
#if !os(macOS)
  func processData(lineData: Data, word: String) {
    lineCounter += 1
    if let line: String = String(data: lineData, encoding: .utf8),
      isWordInLine(line: line, word: word)
    {
      results[lineCounter] = line
    }
  }

  var buffer: Data = Data()
  do {
    while let chunk = try fileHandle.read(upToCount: 4096), !chunk.isEmpty {
      buffer.append(chunk)
      while let newLineIndex = buffer.firstIndex(of: 0x0A) {
        // Get from the start of the buffer, but before \n
        let lineData = buffer[buffer.startIndex..<newLineIndex]
        processData(lineData: lineData, word: word)
        // Clean the buffer and remove from start of the buffer, including \n
        buffer.removeSubrange(buffer.startIndex...newLineIndex)
      }
    }

    if !buffer.isEmpty {
      processData(lineData: buffer, word: word)
    }
  } catch {}
#endif

  do {
    for try await line: String in fileHandle.bytes.lines {
      lineCounter += 1
      if isWordInLine(line: line, word: word) {
        results[lineCounter] = line
      }
    }
  } catch {}

  return results
}

@main
struct SwiftFind: AsyncParsableCommand {
  @Argument(help: "The word to search.")
  var word: String
  @Argument(help: "The path to scan files for the given word.")
  var path: String? = nil
  @Option(
    help: "The allowlist of file extensions.",
    transform: { Set($0.split(separator: ",").map(String.init)) })
  var extensions: Set<String>? = nil
  @Option(
    help: "The denylist of directory names.",
    transform: { Set($0.split(separator: ",").map(String.init)) })
  var exclude: Set<String>? = nil

  mutating func run() async throws {
    let res = findFilesInPath(path: path, excluding: exclude, recursively: true)
    for r in res {
      let result: [Int : String] = await findWordInFile(file: r, word: word)
      if !result.isEmpty {
        print(r, result)
      }
    }
  }
}
