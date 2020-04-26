
import Foundation

class Environment {

    let enclosing: Environment?
    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }

    private var expressions: [Expression.Variable: Expression?] = [:]

    func define(_ expression: Expression?, for variable: Expression.Variable) {
        expressions[variable] = expression
    }

    func get(_ variable: Expression.Variable) throws -> Expression? {

        if let expression = expressions[variable] {
            return expression
        }

        if let enclosing = enclosing {
            return try enclosing.get(variable)
        }

        throw UndefinedVariable(variable: variable)
    }

    func assign(_ expression: Expression, for variable: Expression.Variable) throws {

        if expressions.keys.contains(variable) {
            expressions[variable] = expression
        }

        if let enclosing = enclosing {
            try enclosing.assign(expression, for: variable)
        }

        throw UndefinedVariable(variable: variable)
    }
}

struct UndefinedVariable: LocalizedError {
    let variable: Expression.Variable
    var errorDescription: String? { "Undefined variable \(variable.name)." }
}
