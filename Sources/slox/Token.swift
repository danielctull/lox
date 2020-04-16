
struct Token {
    let type: TokenType
    let lexeme: String
    let line: Int
}

extension Token: CustomStringConvertible {

    var description: String { "\(type) \(lexeme)" }
}
