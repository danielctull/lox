
extension Expression {

    func fold<Result>(
        literal literalTransform: (Literal) -> Result,
        unary unaryTransform: (Unary) -> Result,
        binary binaryTransform: (Binary) -> Result,
        grouping groupingTransform: (Grouping) -> Result
    ) -> Result {

        switch self {
        case let .literal(literal): return literalTransform(literal)
        case let .unary(unary): return unaryTransform(unary)
        case let .binary(binary): return binaryTransform(binary)
        case let .grouping(grouping): return groupingTransform(grouping)
        }
    }
}

extension Expression.Literal {

    func fold<Result>(
        number numberTransform: (Double) -> Result,
        string stringTransform: (String) -> Result,
        true: @autoclosure () -> Result,
        false: @autoclosure () -> Result,
        nil: @autoclosure () -> Result
    ) -> Result {

        switch self {
            case .number(let number): return numberTransform(number)
            case .string(let string): return stringTransform(string)
            case .true: return `true`()
            case .false: return `false`()
            case .nil: return `nil`()
        }
    }
}

extension Expression.Unary.Operator {

    func fold<Result>(
        negative: @autoclosure () -> Result,
        not: @autoclosure () -> Result
    ) -> Result {
        switch self {
        case .negative: return negative()
        case .not: return not()
        }
    }
}


extension Expression.Binary.Operator {

    func fold<Result>(
        equalEqual: @autoclosure () -> Result,
        notEqual: @autoclosure () -> Result,
        less: @autoclosure () -> Result,
        lessEqual: @autoclosure () -> Result,
        greater: @autoclosure () -> Result,
        greaterEqual: @autoclosure () -> Result,
        plus: @autoclosure () -> Result,
        minus: @autoclosure () -> Result,
        multiply: @autoclosure () -> Result,
        divide: @autoclosure () -> Result
    ) -> Result {
        switch self {
        case .equalEqual: return equalEqual()
        case .notEqual: return notEqual()
        case .less: return less()
        case .lessEqual: return lessEqual()
        case .greater: return greater()
        case .greaterEqual: return greaterEqual()
        case .plus: return plus()
        case .minus: return minus()
        case .multiply: return multiply()
        case .divide: return divide()
        }
    }
}



extension Expression {


    var string: String {

        return fold(literal: { (literal) -> String in
""
//            "" literal.fold(number: { v -> String in String(v) },
//                    string: \.self,
//                    true: "true" ,
//                    false: "false",
//                    nil: "nil")

        }, unary: { unary -> String in

            let op = unary.operator.fold(
                negative: "-",
                not: "!"
            )

            return "(\(op) \(unary.expression.string))"

        }, binary: { binary -> String in

            let op = binary.operator.fold(
                equalEqual: "==",
                notEqual: "!=",
                less: "<",
                lessEqual: "<=",
                greater: ">",
                greaterEqual: ">=",
                plus: "+",
                minus: "-",
                multiply: "*",
                divide: "/"
            )

            return "(\(op) \(binary.lhs.string) \(binary.rhs.string))"

        }, grouping: { grouping -> String in
            "(group \(grouping.expression.string)"
        })
    }
}
