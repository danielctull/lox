
struct Token {
    let type: TokenType
    let lexeme: String
    let literal: Any
    let line: Int
}

extension Token: CustomStringConvertible {

    var description: String { "\(type) \(lexeme) \(literal)" }
}
