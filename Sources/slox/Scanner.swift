
import Foundation

final class Scanner {

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
    init(source: String) {
        self.source = source
        scanner = ItemScanner(source)
        start = scanner.index
    }

    private var errors: [LoxError] = []
    private var tokens: [Token] = []
    private var scanner: ItemScanner<String>
    private var start: String.Index
    private var line = 1

    func scanTokens() throws -> [Token] {

        errors = []
        tokens = []
        scanner = ItemScanner(source)
        start = scanner.index

        while scanner.index < source.endIndex {
            start = scanner.index
            try scanToken()
        }

        guard errors.isEmpty else { throw MultipleError(errors: errors) }

        tokens.append(Token(type: .eof, lexeme: "", line: line))
        return tokens
    }

    private func scanToken() throws {

        let character = scanner.advance()
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

        case "!": addToken(scanner.match("=") ? .bangEqual : .bang)
        case "=": addToken(scanner.match("=") ? .equalEqual : .equal)
        case "<": addToken(scanner.match("=") ? .lessEqual : .less)
        case ">": addToken(scanner.match("=") ? .greaterEqual : .greater)

        case "/":
            // Handle commented code and ignore it all
            guard scanner.match("/") else { addToken(.slash); return }
            while let next = scanner.current, next != "\n" { scanner.advance() }

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

        while let next = scanner.current, next != "\"" {
            if next == "\n" { line += 1 }
            scanner.advance()
        }

        guard scanner.index < source.endIndex else {
            addError("Unterminated string.")
            return
        }

        let index = source.index(after: start)
        let value = source[index..<scanner.index]

        // The closing ".
        scanner.advance()

        addToken(.string(String(value)))
    }

    private func scanNumber() {

        while let current = scanner.current, isDigit(current) { scanner.advance() }

        // Look for fractional part
        if let current = scanner.current, current == ".", let next = scanner.next, isDigit(next) {

            // Consume the "."
            scanner.advance()

            while let current = scanner.current, isDigit(current) { scanner.advance() }
        }

        let string = String(source[start..<scanner.index])
        let double = Double(string)! // Pretty confident this will work!
        addToken(.number(double))

    }

    private func scanIdentifier() {

        while let current = scanner.current, isAlphaNumeric(current) { scanner.advance() }

        let text = String(source[start..<scanner.index])
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

    private func addError(_ message: String) {
        let error = LoxError(line: line, message: message)
        errors.append(error)
    }

    private func addToken(_ type: TokenType) {
        let text = source[start..<scanner.index]
        tokens.append(Token(type: type, lexeme: String(text), line: line))
    }
}
