
import Foundation

struct Environment {

    private var expressions: [Expression.Variable: Expression?] = [:]

    mutating func set(_ expression: Expression?, for variable: Expression.Variable) {
        expressions[variable] = expression
    }

    func get(_ variable: Expression.Variable) throws -> Expression? {

        guard let expression = expressions[variable] else {
            throw UndefinedVariable(variable: variable)
        }

        return expression
    }
}

struct UndefinedVariable: LocalizedError {
    let variable: Expression.Variable
    var errorDescription: String? { "Undefined variable \(variable.name)." }
}
