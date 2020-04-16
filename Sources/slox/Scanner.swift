
import Foundation

final class Scanner {

    private let source: String
    init(source: String) {
        self.source = source
        start = source.startIndex
        current = start
    }

    private var errors: [LoxError] = []
    private var tokens: [Token] = []
    private var start: String.Index
    private var current: String.Index
    private var line = 1

    func scanTokens() throws -> [Token] {

        tokens = []
        start = source.startIndex
        current = start

        while current < source.endIndex {
            start = current
            try scanToken()
        }

        guard errors.isEmpty else { throw MultipleError(errors: errors) }

        tokens.append(Token(type: .eof, lexeme: "", line: line))
        return tokens
    }

    private func scanToken() throws {

        let character = advance()
        switch (character) {
        case "(": addToken(.leftParenthesis)
        case ")": addToken(.rightParenthesis)
        case "{": addToken(.leftBrace)
        case "}": addToken(.rightBrace)
        case ",": addToken(.comma)
        case ".": addToken(.dot)
        case "-": addToken(.minus)
        case "+": addToken(.plus)
        case ";": addToken(.semicolon)
        case "*": addToken(.star)

        case "!": addToken(match("=") ? .bangEqual : .bang)
        case "=": addToken(match("=") ? .equalEqual : .equal)
        case "<": addToken(match("=") ? .lessEqual : .less)
        case ">": addToken(match("=") ? .greaterEqual : .greater)

        case "/":
            // Handle commented code and ignore it all
            guard match("/") else { addToken(.slash); return }
            while let next = peek(), next != "\n" { _ = advance() }

        // Ignore whitespace
        case " ", "\r", "\t": break
        case "\n": line += 1

        default: addError("Unexpected character: \(character)")
        }
    }

    private func peek() -> Character? {
        guard current < source.endIndex else { return nil }
        return source[current]
    }

    private func match(_ expected: Character) -> Bool {
        guard current < source.endIndex else { return false }
        guard source[current] == expected else { return false }
        current = source.index(after: current)
        return true
    }

    private func addError(_ message: String) {
        let error = LoxError(line: line, message: message)
        errors.append(error)
    }

    private func advance() -> Character {
        defer { current = source.index(after: current) }
        return source[current]
    }

    private func addToken(_ type: TokenType) {
        let text = source[start..<current]
        tokens.append(Token(type: type, lexeme: String(text), line: line))
    }
}
