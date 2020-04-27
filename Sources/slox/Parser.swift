
import Foundation

final class Parser {

    private let tokens: [Token]
    private var errors: [Error] = []
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() throws -> [Statement] {
        var statements: [Statement] = []
        while !isAtEnd {

            do {
                statements.append(try declaration())
            } catch {
                errors.append(error)
                synchronize()
            }
        }

        guard errors.count == 0 else {
            throw MultipleError(errors: errors)
        }

        return statements
    }

    private func declaration() throws -> Statement {

        if match(.var) { return try varStatement() }

        return try statement()
    }

    private func statement() throws -> Statement {
        if match(.if) { return try ifStatement() }
        if match(.print) { return try printStatement() }
        if match(.leftBrace) { return try blockStatement() }

        return try expressionStatement()
    }

    private func blockStatement() throws -> Statement {
        var statements: [Statement] = []
        while (!check(.rightBrace) && !isAtEnd) {
            statements.append(try declaration())
        }
        try consume(type: .rightBrace)
        return .block(statements)
    }

    private func ifStatement() throws -> Statement {
        try consume(type: .leftParenthesis)
        let condition = try expression()
        try consume(type: .rightParenthesis)

        let then = try statement()
        var `else`: Statement? = nil
        if match(.else) { `else` = try statement() }

        return .if(condition: condition, then: then, else: `else`)

    }

    private func printStatement() throws -> Statement {
        let expression = try self.expression()
        try consume(type: .semicolon)
        return .print(expression)
    }

    private func varStatement() throws -> Statement {
        let token = try consume(type: .identifier)
        let variable = Expression.Variable(name: token.lexeme)
        let initializer = match(.equal) ? try expression() : nil
        try consume(type: .semicolon)
        return .var(variable, initializer)
    }

    private func expressionStatement() throws -> Statement {
        let expression = try self.expression()
        try consume(type: .semicolon)
        return .expression(expression)
    }

    private func expression() throws -> Expression {
        try assignment()
    }

    private func assignment() throws -> Expression {

        let expression = try equality()

        if match(.equal) {
            let value = try assignment()

            if case let .variable(variable) = expression {
                return .assignment(variable: variable, expression: value)
            }

            // We report an error if the left-hand side isn’t a valid assignment
            // target, but we don’t throw it because the parser isn’t in a
            // confused state where we need to go into panic mode and
            // synchronize.
            errors.append(InvalidAssignmentTarget(lhs: expression, rhs: value))
        }

        return expression
    }

    private func equality() throws -> Expression {

        var expression = try comparison()

        while match(.bangEqual, .equalEqual) {

            let `operator`: Expression.Binary.Operator = try {
                switch previous.type {
                case .bangEqual: return .notEqual
                case .equalEqual: return .equalEqual
                default: throw UnexpectedToken(token: previous, expected: .bangEqual, .equalEqual)
                }
            }()

            expression = .binary(lhs: expression,
                                 operator: `operator`,
                                 rhs: try comparison())
        }

        return expression
    }

    private func comparison() throws -> Expression {

        var expression = try addition()

        while match(.greater, .greaterEqual, .less, .lessEqual) {

            let `operator`: Expression.Binary.Operator = try {
                switch previous.type {
                case .greater: return .greater
                case .greaterEqual: return .greaterEqual
                case .less: return .less
                case .lessEqual: return .lessEqual
                default: throw UnexpectedToken(token: previous, expected: .greater, .greaterEqual, .less, .lessEqual)
                }
            }()

            expression = .binary(lhs: expression,
                                 operator: `operator`,
                                 rhs: try addition())
        }

        return expression
    }

    private func addition() throws -> Expression {

        var expression = try multiplication()

        while match(.minus, .plus) {

            let `operator`: Expression.Binary.Operator = try {
                switch previous.type {
                case .minus: return .minus
                case .plus: return .plus
                default: throw UnexpectedToken(token: previous, expected: .minus, .plus)
                }
            }()

            expression = .binary(lhs: expression,
                                 operator: `operator`,
                                 rhs: try multiplication())
        }

        return expression
    }

    private func multiplication() throws -> Expression {

        var expression = try unary()

        while match(.slash, .star) {

            let `operator`: Expression.Binary.Operator = try {
                switch previous.type {
                case .slash: return .divide
                case .star: return .multiply
                default: throw UnexpectedToken(token: previous, expected: .slash, .star)
                }
            }()

            expression = .binary(lhs: expression,
                                 operator: `operator`,
                                 rhs: try unary())
        }

        return expression
    }

    private func unary() throws -> Expression {

        guard match(.bang, .minus) else { return try primary() }

        let `operator`: Expression.Unary.Operator = try {
            switch previous.type {
            case .bang: return .not
            case .minus: return .negative
            default: throw UnexpectedToken(token: previous, expected: .bang, .minus)
            }
        }()

        return .unary(operator: `operator`,
                      expression: try unary())
    }

    private func primary() throws -> Expression {

        let current = advance()
        switch current.type {
        case .false: return .literal(.false)
        case .true: return .literal(.true)
        case .nil: return .literal(.nil)
        case .number(let number): return .literal(.number(number))
        case .string(let string): return .literal(.string(string))
        case .identifier: return .variable(name: previous.lexeme)

        case .leftParenthesis:
            let output = Expression.grouping(expression: try expression())
            try consume(type: .rightParenthesis)
            return output

        default:
            throw UnexpectedToken(token: current, expected: .false, .true, .nil, .number(0), .string(""))
        }
    }

    private func synchronize() {

        advance()

        // Discard tokens until we're at a statement boundary, which is after
        // a semi-colon or just before class, fun, var, for, if, while, print or
        // return statements.
        while !isAtEnd {

            guard previous.type != .semicolon else { return }

            switch peek.type {

            case .class,
                 .fun,
                 .var,
                 .for,
                 .if,
                 .while,
                 .print,
                 .return: return

            default: advance()
            }
        }
    }

    // Consuming
    private func match(_ types: TokenType...) -> Bool {

        for type in types {
            if check(type) {
                advance()
                return true
            }
        }

        return false
    }

    private func check(_ type: TokenType) -> Bool {
        guard !isAtEnd else { return false }
        return peek.type == type
    }

    @discardableResult
    private func advance() -> Token {
        defer { current += 1 }
        return tokens[current]
    }

    @discardableResult
    private func consume(type: TokenType) throws -> Token {
        guard check(type) else { throw UnexpectedToken(token: peek, expected: type) }
        return advance()
    }

    private var isAtEnd: Bool { peek.type == .eof }

    private var peek: Token { tokens[current] }

    private var previous: Token { tokens[current - 1] }
}

struct InvalidAssignmentTarget: LocalizedError {
    let lhs: Expression
    let rhs: Expression
    var errorDescription: String? { "Invalid Assignment Target: \(lhs)" }
}

struct UnexpectedToken: LocalizedError {

    init(token: Token, expected: TokenType...) {
        self.token = token
        self.expected = expected
    }

    let token: Token
    let expected: [TokenType]

    var errorDescription: String? { description }

    var description: String {
        let expectations = expected.map(String.init(describing:)).joined(separator: ", ")
        return "[line: \(token.line)] Expected \(expectations) but found \(token.type) \(token.lexeme)"
    }
}
