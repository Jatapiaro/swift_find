import ArgumentParser

@main
struct swiftfind: ParsableCommand {
    @Argument(help: "The word to search.")
    var word: String

    mutating func run() throws {
        print("Hello, world! \(word)")
    }
}
