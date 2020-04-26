
import Foundation

struct Environment {

    private var expressions: [Expression.Variable: Expression?] = [:]

    mutating func define(_ expression: Expression?, for variable: Expression.Variable) {
        expressions[variable] = expression
    }

    func get(_ variable: Expression.Variable) throws -> Expression? {

        guard let expression = expressions[variable] else {
            throw UndefinedVariable(variable: variable)
        }

        return expression
    }

    mutating func assign(_ expression: Expression, for variable: Expression.Variable) throws {

        guard expressions.keys.contains(variable) else {
            throw UndefinedVariable(variable: variable)
        }

        expressions[variable] = expression
    }
}

struct UndefinedVariable: LocalizedError {
    let variable: Expression.Variable
    var errorDescription: String? { "Undefined variable \(variable.name)." }
}
