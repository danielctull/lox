
indirect enum Expression {

    case literal(Literal)
    case unary(Unary)
    case binary(Binary)
    case grouping(Grouping)

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
}
