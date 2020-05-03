
public indirect enum Expression {

    case assignment(Assignment)
    case literal(Literal)
    case logical(Logical)
    case unary(Unary)
    case binary(Binary)
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

    static func logical(lhs: Expression,
                        `operator`: Logical.Operator,
                        rhs: Expression) -> Expression {

        .logical(Logical(lhs: lhs, operator: `operator`, rhs: rhs))
    }

    static func unary(`operator`: Unary.Operator,
                      expression: Expression) -> Expression {
        .unary(Unary(operator: `operator`, expression: expression))
    }

    static func grouping(expression: Expression) -> Expression {
        .grouping(Grouping(expression: expression))
    }

    static func variable(name: String) -> Expression {
        .variable(Variable(name: name))
    }
}
