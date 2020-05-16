
import Foundation

final class Environment {

    private let enclosing: Environment?
    private let name: String
    init(name: String, enclosing: Environment? = nil) {
        self.enclosing = enclosing
        self.name = name
    }

    private var values: [Expression.Variable: Value?] = [:]

    func define(_ value: Value?, for variable: Expression.Variable) {
        values[variable] = value
    }

    func get(_ variable: Expression.Variable) throws -> Value? {

        if let value = values[variable] {
            return value
        }

        if let enclosing = enclosing {
            return try enclosing.get(variable)
        }

        throw UndefinedVariable(variable: variable)
    }

    func assign(_ value: Value, for variable: Expression.Variable) throws {

        if values.keys.contains(variable) {
            values[variable] = value
            return
        }

        if let enclosing = enclosing {
            try enclosing.assign(value, for: variable)
            return
        }

        throw UndefinedVariable(variable: variable)
    }
}

struct UndefinedVariable: LocalizedError {
    let variable: Expression.Variable
    var errorDescription: String? { "Undefined variable \(variable.name)." }
}

extension Environment: CustomStringConvertible {

    func description(level: Int = 0) -> [String] {

        let name = withUnsafePointer(to: self) { self.name + " (\($0))" }

        let values = self.values
            .map { "\($0.key.name): \($0.value?.description ?? "nil")" }

        let underline = String(repeating: "-", count: name.count)
        let indentation = String(repeating: " ", count: level * 4)
        let lines = ([name, underline] + values).map { indentation + $0 }
        let enclosing = self.enclosing?.description(level: level + 1) ?? []
        return lines + enclosing
    }

    var description: String { description().joined(separator: "\n") }
}
