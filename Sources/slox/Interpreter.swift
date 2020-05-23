
import Foundation

public final class Interpreter {

    public init() {
        environment = globals
        globals.define(.function { .number(Date().timeIntervalSince1970) }, for: "clock")
    }

    let globals = Environment(name: "Global")
    var environment: Environment

    public func interpret(_ statements: [Statement]) throws {
        for statement in statements {
            try execute(statement)
        }
    }
}

// MARK: - Statements

extension Interpreter {

    private func execute(_ statement: Statement) throws {
        switch statement {
        case let .if(statement): try executeIf(statement)
        case let .function(function): try evaluateFunction(function)
        case let .print(expression): Swift.print(try evaluateExpression(expression))
        case let .return(expression): try evaluateReturn(expression)
        case let .expression(expression): _ = try evaluateExpression(expression)
        case let .var(statement): try evaluateVar(statement)
        case let .while(statement): try executeWhile(statement)
        case let .block(block): try executeBlock(block, using: Environment(name: "Block", enclosing: environment))
        }
    }
}

// MARK: - Expressions

extension Interpreter {

    private func executeBlock(_ block: Statement.Block, using new: Environment) throws {

        let previous = environment
        environment = new
        defer { environment = previous }

        for statement in block.statements {
            try execute(statement)
        }
    }

    // Used to unwind the call stack from the evaluation of the return to
    // the execution of the function.
    private struct Return: Error {
        let value: Value
    }

    private func evaluateVar(_ statement: Statement.Var) throws {
        let value = try statement.expression.map(evaluateExpression)
        environment.define(value, for: statement.variable)
    }

    private func evaluateFunction(_ statement: Statement.Function) throws {

        let closure = environment

        let function = Callable(description: statement.description, arity: statement.parameters.count) {
            (interpreter, arguments) -> Value in

            let environment = Environment(name: statement.name.name, enclosing: closure)

            for (parameter, argument) in zip(statement.parameters, arguments) {
               environment.define(argument, for: parameter)
            }

            do {
                try interpreter.executeBlock(statement.body, using: environment)
            } catch let returnError as Return {
                return returnError.value
            }

            return .nil
        }

        environment.define(.callable(function), for: statement.name)
    }

    private func evaluateReturn(_ expression: Expression) throws {
        let value = try evaluateExpression(expression)
        throw Return(value: value)
    }

    private func executeIf(_ statement: Statement.If) throws {
        if try evaluateExpression(statement.condition).isTruthy {
            try execute(statement.then)
        } else if let elseBranch = statement.else {
            try execute(elseBranch)
        }
    }

    private func executeWhile(_ statement: Statement.While) throws {

        while try evaluateExpression(statement.condition).isTruthy {
            try execute(statement.body)
        }
    }

    private func evaluateExpression(_ expression: Expression) throws -> Value {
        switch expression {
        case let .assignment(assignment): return try evaluateAssignment(assignment)
        case let .literal(literal): return evaluateLiteral(literal)
        case let .logical(logical): return try evaluateLogical(logical)
        case let .unary(unary): return try evaluateUnary(unary)
        case let .binary(binary): return try evaluateBinary(binary)
        case let .call(call): return try evaluateCall(call)
        case let .grouping(grouping): return try evaluateGrouping(grouping)
        case let .value(value): return value
        case let .variable(variable): return try evaluateVariable(variable)
        }
    }

    private func evaluateAssignment(_ assignment: Expression.Assignment) throws -> Value {
        let value = try evaluateExpression(assignment.expression)
        try environment.assign(value, for: assignment.variable)
        return value
    }

    private func evaluateLiteral(_ literal: Expression.Literal) -> Value {
        switch literal {
        case .number(let value): return .number(value)
        case .string(let value): return .string(value)
        case .false: return .boolean(false)
        case .true: return .boolean(true)
        case .nil: return .nil
        }
    }

    private func evaluateLogical(_ logical: Expression.Logical) throws -> Value {

        let lhs = try evaluateExpression(logical.lhs)
        switch (logical.operator, lhs.isTruthy) {
        case (.or, true): return lhs
        case (.and, false): return lhs
        default: return try evaluateExpression(logical.rhs)
        }
    }

    private func evaluateUnary(_ unary: Expression.Unary) throws -> Value {

        let value = try evaluateExpression(unary.expression)

        switch (unary.operator, value) {
        case (.negative, .number(let number)): return .number(-number)
        case (.negative, _): throw TypeMismatch(value: value, expected: .number(0))
        case (.not, _): return .boolean(value.isTruthy)
        }
    }

    private func evaluateBinary(_ binary: Expression.Binary) throws -> Value {

        let lhs = try evaluateExpression(binary.lhs)
        let rhs = try evaluateExpression(binary.rhs)

        switch (binary.operator, lhs, rhs) {

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

        default: throw BinaryOperationFailure(operator: binary.operator, lhs: lhs, rhs: rhs)
        }
    }

    private func evaluateCall(_ call: Expression.Call) throws -> Value {
        let callee = try evaluateVariable(call.callee)
        let arguments = try call.arguments.map(evaluateExpression)

        guard case let .callable(function) = callee else {
            throw NotCallable(value: call.callee)
        }

        guard arguments.count == function.arity else {
            throw IncorrectArgumentCount(expected: function.arity, actual: arguments.count)
        }

        return try function.call(self, arguments)
    }

    private func evaluateGrouping(_ grouping: Expression.Grouping) throws -> Value {
        try evaluateExpression(grouping.expression)
    }

    private func evaluateVariable(_ variable: Expression.Variable) throws -> Value {
        try environment.get(variable) ?? .nil
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

extension Value {

    fileprivate var typeName: String {
        switch self {
        case .boolean: return "Boolean"
        case .number: return "Number"
        case .string: return "String"
        case .callable: return "Callable"
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

struct NotCallable: LocalizedError {
    let value: Expression.Variable
    var errorDescription: String? {
        "\(value) is not callable."
    }
}

struct IncorrectArgumentCount: LocalizedError {
    let expected: Int
    let actual: Int
    var errorDescription: String? {
        "Expected \(expected) arguments but got \(actual)."
    }
}
