
import Foundation

struct LoxError: LocalizedError, CustomStringConvertible {

    let line: Int
    let message: String

    var errorDescription: String? { description }

    var description: String {
        "[line: \(line)] Error: \(message)"
    }
}

struct MultipleError: LocalizedError, CustomStringConvertible {

    let errors: [Error]

    var errorDescription: String? { description }

    var description: String {
        errors
            .compactMap { $0.localizedDescription }
            .joined(separator: "\n")
    }
}
