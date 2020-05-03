
public struct Token {
    let type: TokenType
    let lexeme: String
    let line: Int
}

extension Token: CustomStringConvertible {

    public var description: String { "\(type) \(lexeme)" }
}
