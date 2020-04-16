
import Foundation

struct LoxError: LocalizedError {

    let line: Int
    let message: String

    var errorDescription: String? {
        "[line: \(line)] Error: \(message)"
    }
}
