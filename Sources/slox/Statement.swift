
indirect enum Statement {
    case block(Block)
    case expression(Expression)
    case `if`(If)
    case print(Expression)
    case `var`(Expression.Variable, Expression?)
}

extension Statement {

    struct If {
        let condition: Expression
        let then: Statement
        let `else`: Statement?
    }

    struct Block {
        let statements: [Statement]
    }
}

// Conveniences for making statements

extension Statement {

    static func block(_ statements: [Statement]) -> Statement {
        .block(Block(statements: statements))
    }

    static func `if`(condition: Expression, then: Statement, else: Statement?) -> Statement {
        .if(If(condition: condition, then: then, else: `else`))
    }
}
