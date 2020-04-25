
import Foundation

struct Interpreter {

    func interpret(_ statements: [Statement]) throws {
        for statement in statements {
            try statement.execute()
        }
    }
}

enum Value {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case `nil`
}

extension Statement {

    fileprivate func execute() throws {
        switch self {
        case let .print(expression): Swift.print(try expression.evaluate())
        case let .expression(expression): _ = try expression.evaluate()
        }
    }
}

extension Expression {

    fileprivate func evaluate() throws -> Value {
        switch self {
        case let .literal(literal): return literal.value
        case let .unary(unary): return try unary.evaluate()
        case let .binary(binary): return try binary.evaluate()
        case let .grouping(grouping): return try grouping.evaluate()
        }
    }
}

extension Expression.Literal {

    fileprivate var value: Value {
        switch self {
        case .number(let value): return .number(value)
        case .string(let value): return .string(value)
        case .false: return .boolean(false)
        case .true: return .boolean(true)
        case .nil: return .nil
        }
    }
}

extension Expression.Unary {

    fileprivate func evaluate() throws -> Value {

        let value = try expression.evaluate()

        switch (`operator`, value) {
        case (.negative, .number(let number)): return .number(-number)
        case (.negative, _): throw TypeMismatch(value: value, expected: .number(0))
        case (.not, _): return .boolean(value.isTruthy)
        }
    }
}

extension Expression.Binary {

    fileprivate func evaluate() throws -> Value {

        let lhs = try self.lhs.evaluate()
        let rhs = try self.rhs.evaluate()

        switch (`operator`, lhs, rhs) {

        case let (.plus, .number(lhs), .number(rhs)): return .number(lhs + rhs)
        case let (.minus, .number(lhs), .number(rhs)): return .number(lhs - rhs)
        case let (.divide, .number(lhs), .number(rhs)): return .number(lhs / rhs)
        case let (.multiply, .number(lhs), .number(rhs)): return .number(lhs * rhs)

        case let (.plus, .string(lhs), .string(rhs)): return .string(lhs + rhs)

        case let (.less, .number(lhs), .number(rhs)): return .boolean(lhs < rhs)
        case let (.lessEqual, .number(lhs), .number(rhs)): return .boolean(lhs <= rhs)
        case let (.greater, .number(lhs), .number(rhs)): return .boolean(lhs > rhs)
        case let (.greaterEqual, .number(lhs), .number(rhs)): return .boolean(lhs >= rhs)

        case (.equalEqual, _, _): return .boolean(lhs.isEqual(to: rhs))
        case (.notEqual, _, _): return .boolean(!lhs.isEqual(to: rhs))

        default: throw BinaryOperationFailure(operator: `operator`, lhs: lhs, rhs: rhs)
        }
    }
}

extension Expression.Grouping {

    fileprivate func evaluate() throws -> Value {
        try expression.evaluate()
    }
}

extension Value {

    fileprivate var isTruthy: Bool {
        switch self {
        case .boolean(let value): return value
        case .nil: return false
        default: return true
        }
    }

    fileprivate func isEqual(to other: Self) -> Bool {
        switch (self, other) {
        case let (.number(lhs), .number(rhs)): return lhs == rhs
        case let (.string(lhs), .string(rhs)): return lhs == rhs
        case let (.boolean(lhs), .boolean(rhs)): return lhs == rhs
        case (.nil, .nil): return true
        default: return false
        }
    }
}

extension Value: CustomStringConvertible {

    var description: String {
        switch self {
        case let .boolean(value): return value.description
        case let .number(value): return value.description
        case let .string(value): return value
        case .nil: return "nil"
        }
    }
}

extension Value {

    fileprivate var typeName: String {
        switch self {
        case .boolean: return "Boolean"
        case .number: return "Number"
        case .string: return "String"
        case .nil: return "Nil"
        }
    }
}

// MARK: - Errors

struct BinaryOperationFailure: LocalizedError {
    let `operator`: Expression.Binary.Operator
    let lhs: Value
    let rhs: Value

    var errorDescription: String? {
        "Cannot perform operation \(`operator`) between operands \(lhs) and \(rhs)"
    }
}

struct TypeMismatch: LocalizedError {

    let value: Value
    let expected: Value

    var errorDescription: String? {
        "Expected \(expected.typeName) but found \(value.typeName)."
    }
}
