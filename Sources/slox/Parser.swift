
import Foundation

public final class Parser {

    private let tokens: [Token]
    private var errors: [Error] = []
    private var current = 0

    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    public func parse() throws -> [Statement] {
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

        if match(.fun) { return try functionStatement() }
        if match(.var) { return try varStatement() }

        return try statement()
    }

    private func statement() throws -> Statement {
        if match(.for) { return try forStatement() }
        if match(.if) { return try ifStatement() }
        if match(.print) { return try printStatement() }
        if match(.while) { return try whileStatement() }
        if match(.leftBrace) { return try .block(blockStatement()) }

        return try expressionStatement()
    }

    private func blockStatement() throws -> Statement.Block {
        var statements: [Statement] = []
        while (!check(.rightBrace) && !isAtEnd) {
            statements.append(try declaration())
        }
        try consume(type: .rightBrace)
        return Statement.Block(statements: statements)
    }

    // This desugars a for loop into a while loop.
    // So the following:
    //
    // for (var i = 0; i < 10; i = i + 1) print i;
    //
    // Becomes:
    //
    // {
    //   var i = 0;
    //   while (i < 10) {
    //     print i;
    //     i = i + 1;
    //   }
    // }
    private func forStatement() throws -> Statement {

        try consume(type: .leftParenthesis)

        let initializer: Statement?
        if match(.semicolon) {
            initializer = nil
        } else if match(.var) {
            initializer = try varStatement()
        } else {
            initializer = try expressionStatement()
        }

        // If the condition is omitted, we jam in true to make an infinite loop.
        let condition: Expression
        if !check(.semicolon) {
            condition = try expression()
        } else {
            condition = .literal(.true)
        }
        try consume(type: .semicolon)

        let increment: Expression?
        if !check(.rightParenthesis) {
            increment = try expression()
        } else {
            increment = nil
        }
        try consume(type: .rightParenthesis)

        var body = try statement()

        // Add the increment to the end of the body.
        if let increment = increment {
            body = .block([body, .expression(increment)])
        }

        // Add the condition
        body = .while(condition: condition, body: body)

        // Prepend the initializer to before the while loop.
        if let initializer = initializer {
            body = .block([initializer, body])
        }

        return body
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

    private func whileStatement() throws -> Statement {
        try consume(type: .leftParenthesis)
        let condition = try expression()
        try consume(type: .rightParenthesis)
        let body = try statement()
        return .while(condition: condition, body: body)
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

    private func functionStatement() throws -> Statement {
        let token = try consume(type: .identifier)
        let name = Expression.Variable(name: token.lexeme)

        // Parameters
        try consume(type: .leftParenthesis)
        var paramters: [Expression.Variable] = []
        if !check(.rightParenthesis) {
            repeat {
                if paramters.count > 255 {
                    errors.append(TooManyParameters(name: name))
                }
                let token = try consume(type: .identifier)
                let parameter = Expression.Variable(name: token.lexeme)
                paramters.append(parameter)
            } while match(.comma)
        }
        try consume(type: .rightParenthesis)

        // Body
        try consume(type: .leftBrace)
        let body = try blockStatement()

        return .function(name: name, parameters: paramters, body: body)
    }

    private func expression() throws -> Expression {
        try assignment()
    }

    private func assignment() throws -> Expression {

        let expression = try or()

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

    private func or() throws -> Expression {

        var expression = try and()

        while match(.or) {
            let rhs = try and()
            expression = .logical(lhs: expression, operator: .or, rhs: rhs)
        }

        return expression
    }

    private func and() throws -> Expression {

        var expression = try equality()

        while match(.and) {
            let rhs = try equality()
            expression = .logical(lhs: expression, operator: .and, rhs: rhs)
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

        guard match(.bang, .minus) else { return try call() }

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

    private func call() throws -> Expression {

        var expression = try primary()

        while (true) {
            if match(.leftParenthesis) {
                expression = try finishCall(callee: expression)
            } else {
                break
            }
        }

        return expression
    }

    private func finishCall(callee: Expression) throws -> Expression {

        guard case .variable(let variable) = callee else {
            struct Failure: Error {}
            throw Failure()
        }

        var arguments: [Expression] = []

        if (!check(.rightParenthesis)) {
            repeat {
                arguments.append(try expression())
            } while match(.comma)
        }

        if arguments.count > 255 {
            errors.append(TooManyArguments(callee: callee))
        }

        let parenthesis = try consume(type: .rightParenthesis)

        return .call(callee: variable,
                     arguments: arguments,
                     line: parenthesis.line)
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

struct TooManyArguments: LocalizedError {
    let callee: Expression
    var errorDescription: String? {
        "Cannot have more than 255 arguments. \(callee)"
    }
}

struct TooManyParameters: LocalizedError {
    let name: Expression.Variable
    var errorDescription: String? {
        "Cannot have more than 255 paramters. \(name)"
    }
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
