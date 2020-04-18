
extension Expression: CustomStringConvertible {

    var description: String {
        switch self {
        case .literal(let literal): return literal.description
        case .unary(let unary): return unary.description
        case .binary(let binary): return binary.description
        case .grouping(let grouping): return grouping.description
        }
    }
}

extension Expression.Literal: CustomStringConvertible {

    var description: String {
        switch self {
        case .number(let number): return number.description
        case .string(let string): return string
        case .true: return "true"
        case .false: return "false"
        case .nil: return "nil"
        }
    }
}

extension Expression.Unary: CustomStringConvertible {

    var description: String { "(\(`operator`) \(expression))" }
}

extension Expression.Unary.Operator: CustomStringConvertible {

    var description: String {
        switch self {
        case .negative: return "-"
        case .not: return "!"
        }
    }
}

extension Expression.Binary: CustomStringConvertible {

    var description: String { "(\(`operator`) \(lhs) \(rhs))" }
}

extension Expression.Binary.Operator: CustomStringConvertible {

    var description: String {
        switch self {
        case .equalEqual: return "=="
        case .notEqual: return "!="
        case .less: return "<"
        case .lessEqual: return "<="
        case .greater: return ">"
        case .greaterEqual: return ">="
        case .plus: return "+"
        case .minus: return "-"
        case .multiply: return "*"
        case .divide: return "/"
        }
    }
}

extension Expression.Grouping: CustomStringConvertible {

    var description: String { "(group \(expression))" }
}
