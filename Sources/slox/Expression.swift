
indirect enum Expression {

    case literal(Literal)
    case unary(Unary)
    case binary(Binary)
    case grouping(Grouping)
    case variable(Variable)

    enum Literal {
        case number(Double)
        case string(String)
        case `true`
        case `false`
        case `nil`
    }

    struct Unary {

        enum Operator {
            case negative
            case not
        }

        let `operator`: Operator
        let expression: Expression
    }

    struct Binary {

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

    struct Grouping {
        let expression: Expression
    }

    struct Variable: Hashable {
        let name: String
    }
}

// Conveniences for making expressions

extension Expression {

    static func binary(lhs: Expression,
                       `operator`: Binary.Operator,
                       rhs: Expression) -> Expression {

        .binary(Binary(lhs: lhs, operator: `operator`, rhs: rhs))
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
