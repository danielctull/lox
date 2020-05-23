
extension Statement: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .block(block): return block.description
        case let .expression(expression): return expression.description
        case let .function(function): return function.description
        case let .if(statement): return statement.description
        case let .print(expression): return "(print \(expression))"
        case let .return(expression): return "(return \(expression))"
        case let .var(statement): return statement.description
        case let .while(statement): return statement.description
        }
    }
}

extension Statement.Block: CustomStringConvertible {

    public var description: String {
        "(block \(statements.map(\.description).joined(separator: " ")))"
    }
}

extension Statement.Function: CustomStringConvertible {
    public var description: String { "(function \(name.name) \(parameters) \(body))" }
}

extension Statement.If: CustomStringConvertible {

    public var description: String {
        let elsePart = self.else.map(\.description).map { " else " + $0 }
        return "(if \(condition) then \(then)\(elsePart ?? "")"
    }
}

extension Statement.Var: CustomStringConvertible {
    public var description: String { "(define \(variable) \(expression?.description ?? ""))" }
}

extension Statement.While: CustomStringConvertible {
    public var description: String { "(while \(condition) \(body))" }
}
