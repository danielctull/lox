
public indirect enum Expression {

    case assignment(Assignment)
    case literal(Literal)
    case logical(Logical)
    case unary(Unary)
    case binary(Binary)
    case call(Call)
    case grouping(Grouping)
    case value(Value)
    case variable(Variable)

    public struct Assignment {
        let variable: Variable
        let expression: Expression
    }

    public enum Literal {
        case number(Double)
        case string(String)
        case `true`
        case `false`
        case `nil`
    }

    public struct Logical {

        enum Operator {
            case or
            case and
        }

        let lhs: Expression
        let `operator`: Operator
        let rhs: Expression
    }

    public struct Unary {

        enum Operator {
            case negative
            case not
        }

        let `operator`: Operator
        let expression: Expression
    }

    public struct Binary {

        enum Operator {
            case equalEqual
            case notEqual
            case less
            case lessEqual
            case greater
            case greaterEqual
            case plus
            case minus
            case multiply
            case divide
        }

        let lhs: Expression
        let `operator`: Operator
        let rhs: Expression
    }

    public struct Call {
        let callee: Expression.Variable
        let arguments: [Expression]
        let line: Int
    }

    public struct Grouping {
        let expression: Expression
    }

    public struct Variable: Hashable {
        let name: String
    }
}

// Conveniences for making expressions

extension Expression {

    static func assignment(variable: Variable, expression: Expression) -> Expression {
        .assignment(Assignment(variable: variable, expression: expression))
    }

    static func binary(lhs: Expression,
                       `operator`: Binary.Operator,
                       rhs: Expression) -> Expression {

        .binary(Binary(lhs: lhs, operator: `operator`, rhs: rhs))
    }

    static func call(callee: Expression.Variable, arguments: [Expression], line: Int) -> Expression {
        .call(Call(callee: callee, arguments: arguments, line: line))
    }

    static func logical(lhs: Expression,
                        `operator`: Logical.Operator,
                        rhs: Expression) -> Expression {

        .logical(Logical(lhs: lhs, operator: `operator`, rhs: rhs))
    }

    static func unary(`operator`: Unary.Operator,
                      expression: Expression) -> Expression {
        .unary(Unary(operator: `operator`, expression: expression))
    }

    static func function(_ function: @escaping () throws -> Value) -> Expression {
        .function(arity: 0, { _, _ in try function() })
    }

    static func function(
        arity: Int,
        _ function: @escaping (Interpreter, [Value]) throws -> Value
    ) -> Expression {
        .value(.callable(Callable(description: "<native function>",
                                  arity: arity,
                                  call: function)))
    }

    static func grouping(expression: Expression) -> Expression {
        .grouping(Grouping(expression: expression))
    }

    static func variable(name: String) -> Expression {
        .variable(Variable(name: name))
    }
}

extension Expression.Variable: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}
