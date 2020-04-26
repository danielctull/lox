
enum Statement {
    case block(Block)
    case expression(Expression)
    case print(Expression)
    case `var`(Expression.Variable, Expression?)
}

extension Statement {

    struct Block {
        let statements: [Statement]
    }
}

// Conveniences for making statements

extension Statement {

    static func block(_ statements: [Statement]) -> Statement {
        .block(Block(statements: statements))
    }
}


