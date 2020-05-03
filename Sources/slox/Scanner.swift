
import Foundation

public final class Scanner {

    private let keywords: [String: TokenType] = [
        "and": .and,
        "class": .class,
        "else": .else,
        "false": .false,
        "fun": .fun,
        "for": .for,
        "if": .if,
        "nil": .nil,
        "or": .or,
        "print": .print,
        "return": .return,
        "super": .super,
        "this": .this,
        "true": .true,
        "var": .var,
        "while": .while
    ]

    private let source: String
    public init(source: String) {
        self.source = source
        start = source.startIndex
        current = start
    }

    private var errors: [LoxError] = []
    private var tokens: [Token] = []
    private var start: String.Index
    private var current: String.Index
    private var line = 1

    public func scanTokens() throws -> [Token] {

        errors = []
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

        case "\"": scanString()

        case "0"..."9": scanNumber()

        case "a"..."z", "A"..."Z", "_": scanIdentifier()

        default: addError("Unexpected character: \(character)")
        }
    }

    private func scanString() {

        while let next = peek(), next != "\"" {
            if next == "\n" { line += 1 }
            advance()
        }

        guard current < source.endIndex else {
            addError("Unterminated string.")
            return
        }

        let index = source.index(after: start)
        let value = source[index..<current]

        // The closing ".
        advance()

        addToken(.string(String(value)))
    }

    private func scanNumber() {

        while let now = peek(), isDigit(now) { advance() }

        // Look for fractional part
        if let now = peek(), now == ".", let next = peekNext(), isDigit(next) {

            // Consume the "."
            advance()

            while let now = peek(), isDigit(now) { advance() }
        }

        let string = String(source[start..<current])
        let double = Double(string)! // Pretty confident this will work!
        addToken(.number(double))

    }

    private func scanIdentifier() {

        while let now = peek(), isAlphaNumeric(now) { advance() }

        let text = String(source[start..<current])
        if let keywordType = keywords[text] {
            addToken(keywordType)
        } else {
            addToken(.identifier)
        }
    }

    private func isDigit(_ character: Character) -> Bool {
        ("0"..."9").contains(character)
    }

    private func isAlpha(_ character: Character) -> Bool {
        character == "_"
            || ("a"..."z").contains(character)
            || ("A"..."Z").contains(character)
    }

    private func isAlphaNumeric(_ character: Character) -> Bool {
        isAlpha(character) || isDigit(character)
    }

    private func peekNext() -> Character? {
        let index = source.index(after: current)
        guard index < source.endIndex else { return nil }
        return source[index]
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

    @discardableResult
    private func advance() -> Character {
        defer { current = source.index(after: current) }
        return source[current]
    }

    private func addToken(_ type: TokenType) {
        let text = source[start..<current]
        tokens.append(Token(type: type, lexeme: String(text), line: line))
    }
}
