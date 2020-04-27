
indirect enum Statement {
    case block(Block)
    case expression(Expression)
    case `if`(If)
    case print(Expression)
    case `var`(Expression.Variable, Expression?)
    case `while`(While)
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

    struct While {
        let condition: Expression
        let body: Statement
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

    static func `while`(condition: Expression, body: Statement) -> Statement {
        .while(While(condition: condition, body: body))
    }
}
