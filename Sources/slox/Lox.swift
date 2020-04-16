
import ArgumentParser
import Foundation

struct Lox: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "slox")

    @Argument(help: "The lox file to read in.")
    var file: String?

    func run() throws {

        if let file = file {
            try runFile(file)
        } else {
            runPrompt()
        }
    }

    func runFile(_ file: String) throws {

        guard let directory = Process().currentDirectoryURL else {
            struct NoCurrentDirectoryURL: Error {}
            throw NoCurrentDirectoryURL()
        }

        let url = directory.appendingPathComponent(file)
        let code = try String(contentsOf: url)
        try runCode(code)
    }

    func runPrompt() {

        print("> ", terminator: "")

        while let line = readLine() {

            do {
                try runCode(line)
            } catch {
                print(error)
            }

            print("> ", terminator: "")
        }
    }

    func runCode(_ code: String) throws {
        let scanner = Scanner(source: code)
        for token in try scanner.scanTokens() {
            print(token)
        }
    }
}
