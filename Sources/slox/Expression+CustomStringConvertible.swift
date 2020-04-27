
extension Expression: CustomStringConvertible {

    var description: String {
        switch self {
        case .assignment(let assignment): return assignment.description
        case .literal(let literal): return literal.description
        case .logical(let logical): return logical.description
        case .unary(let unary): return unary.description
        case .binary(let binary): return binary.description
        case .grouping(let grouping): return grouping.description
        case .variable(let variable): return variable.description
        }
    }
}

extension Expression.Assignment: CustomStringConvertible {
    var description: String { "(= \(variable.name) \(expression))" }
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

extension Expression.Logical: CustomStringConvertible {

    var description: String { "(\(`operator`) \(lhs) \(rhs))" }
}

extension Expression.Logical.Operator: CustomStringConvertible {

    var description: String {
        switch self {
        case .and: return "and"
        case .or: return "or"
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


extension Expression.Variable: CustomStringConvertible {
    var description: String { "(var \(name))" }
}
