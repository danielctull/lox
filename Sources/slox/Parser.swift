
import Foundation

final class Parser {

    private let scanner: ItemScanner<[Token]>
    private var current = 0

    init(tokens: [Token]) {
        self.scanner = ItemScanner(tokens, isEnd: { $0.type == .eof })
    }

    func parse() throws -> Expression {
        try expression()
    }

    private func expression() throws -> Expression {
        try equality()
    }

    private func equality() throws -> Expression {

        var expression = try comparison()

        while scanner.match(\.type, .bangEqual, .equalEqual) {

            let `operator`: Expression.Binary.Operator = try {
                switch scanner.previous?.type {
                case .bangEqual: return .notEqual
                case .equalEqual: return .equalEqual
                default: throw UnexpectedToken(token: scanner.previous!, expected: .bangEqual, .equalEqual)
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

        while scanner.match(\.type, .greater, .greaterEqual, .less, .lessEqual) {

            let `operator`: Expression.Binary.Operator = try {
                switch scanner.previous?.type {
                case .greater: return .greater
                case .greaterEqual: return .greaterEqual
                case .less: return .less
                case .lessEqual: return .lessEqual
                default: throw UnexpectedToken(token: scanner.previous!, expected: .greater, .greaterEqual, .less, .lessEqual)
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

        while scanner.match(\.type, .minus, .plus) {

            let `operator`: Expression.Binary.Operator = try {
                switch scanner.previous?.type {
                case .minus: return .minus
                case .plus: return .plus
                default: throw UnexpectedToken(token: scanner.previous!, expected: .minus, .plus)
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

        while scanner.match(\.type, .slash, .star) {

            let `operator`: Expression.Binary.Operator = try {
                switch scanner.previous?.type {
                case .slash: return .divide
                case .star: return .multiply
                default: throw UnexpectedToken(token: scanner.previous!, expected: .slash, .star)
                }
            }()

            expression = .binary(lhs: expression,
                                 operator: `operator`,
                                 rhs: try unary())
        }

        return expression
    }

    private func unary() throws -> Expression {

        guard scanner.match(\.type, .bang, .minus) else { return try primary() }

        let `operator`: Expression.Unary.Operator = try {
            switch scanner.previous?.type {
            case .bang: return .not
            case .minus: return .negative
            default: throw UnexpectedToken(token: scanner.previous!, expected: .bang, .minus)
            }
        }()

        return .unary(operator: `operator`,
                      expression: try unary())
    }

    private func primary() throws -> Expression {

        let current = scanner.advance()
        switch current.type {
        case .false: return .literal(.false)
        case .true: return .literal(.true)
        case .nil: return .literal(.nil)
        case .number(let number): return .literal(.number(number))
        case .string(let string): return .literal(.string(string))

        case .leftParenthesis:
            let output = Expression.grouping(expression: try expression())
            try consume(type: .rightParenthesis)
            return output

        default:
            throw UnexpectedToken(token: current, expected: .false, .true, .nil, .number(0), .string(""))
        }
    }

    private func synchronize() {

        scanner.advance()

        // Discard tokens until we're at a statement boundary, which is after
        // a semi-colon or just before class, fun, var, for, if, while, print or
        // return statements.
        while !scanner.isAtEnd {

            guard scanner.previous?.type != .semicolon else { return }

            switch scanner.current?.type {

            case .class,
                 .fun,
                 .var,
                 .for,
                 .if,
                 .while,
                 .print,
                 .return: return

            default: scanner.advance()
            }
        }
    }

    @discardableResult
    private func consume(type: TokenType) throws -> Token {
        guard scanner.check(\.type, type) else {
            throw UnexpectedToken(token: scanner.current!, expected: type)
        }
        return scanner.advance()
    }
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
        return "[line: \(token.line)] Expected \(expectations) but found \(token.type)"
    }
}



final class ItemScanner<C> where C: BidirectionalCollection {

    typealias Element = C.Element
    typealias Index = C.Index

    var index: Index
    let elements: C
    private let isEnd: (Element) -> Bool

    init(_ elements: C,
         isEnd: @escaping (Element) -> Bool = { _ in false }) {
        self.elements = elements
        self.isEnd = isEnd
        self.index = elements.startIndex
    }

    var isAtEnd: Bool {
        guard let element = current else { return true }
        return isEnd(element)
    }

    var previous: Element? {
        let previous = elements.index(before: index)
        guard previous >= elements.startIndex else { return nil }
        return elements[previous]
    }

    var current: Element? {
        guard index < elements.endIndex else { return nil }
        return elements[index]
    }

    var next: Element? {
        let next = elements.index(after: index)
        guard next < elements.endIndex else { return nil }
        return elements[next]
    }

    @discardableResult
    func advance() -> Element {
        defer { index = elements.index(after: index) }
        return elements[index]
    }

    func check<Property: Equatable>(
        _ keyPath: KeyPath<Element, Property>,
        _ property: Property
    ) -> Bool {
        guard let element = current else { return false }
        guard !isEnd(element) else { return false }
        return element[keyPath: keyPath] == property
    }

    func match<Property: Equatable>(
        _ keyPath: KeyPath<Element, Property>,
        _ expected: Property...
    ) -> Bool {
        match(keyPath, expected)
    }

    func match<Property: Equatable>(
        _ keyPath: KeyPath<Element, Property>,
        _ expected: [Property]
    ) -> Bool {

        for property in expected {
            if check(keyPath, property) {
                index = elements.index(after: index)
                return true
            }
        }

        return false
    }
}

extension ItemScanner where C.Element: Equatable {

    func check(_ element: Element) -> Bool {
        check(\.self, element)
    }

    func match(_ expected: Element...) -> Bool {
        match(\.self, expected)
    }
}
