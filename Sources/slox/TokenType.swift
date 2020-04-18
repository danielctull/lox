
enum TokenType: Equatable {

    // Single-character tokens
    case leftParenthesis
    case rightParenthesis
    case leftBrace
    case rightBrace
    case comma
    case dot
    case minus
    case plus
    case semicolon
    case slash
    case star

    // One or two character tokens
    case bang
    case bangEqual
    case equal
    case equalEqual
    case greater
    case greaterEqual
    case less
    case lessEqual

    // Literals
    case identifier
    case string(String)
    case number(Double)

    // Keywords
    case and
    case `class`
    case `else`
    case `false`
    case fun
    case `for`
    case `if`
    case `nil`
    case or
    case print
    case `return`
    case `super`
    case this
    case `true`
    case `var`
    case `while`

    case eof
}
