
enum Statement {
    case expression(Expression)
    case print(Expression)
    case `var`(Expression.Variable, Expression?)
}
