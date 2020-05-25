
class Resolver {

    let interpreter: Interpreter
    private var scopes = Stack<[String: Bool]>()
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }

    private func beginScope() { scopes.push([:]) }
    private func endScope() { scopes.pop() }
    private func declare(_ variable: Expression.Variable) {}
    private func define(_ variable: Expression.Variable) {}

    private func resolve(_ block: Statement.Block) {
        beginScope()
        block.statements.forEach(resolve)
        endScope()
    }

    private func resolve(_ statement: Statement) {
        switch statement {
        case let .block(block): resolve(block)
        default: break
        }
    }

    private func resolve(_ var: Statement.Var) {
        declare(`var`.variable)
        if let expression = `var`.expression {
            resolve(expression)
        }
        define(`var`.variable)
    }

    private func resolve(_ expression: Expression) {

    }
}

private struct Stack<Element> {

    private var elements: [Element] = []

    mutating func push(_ element: Element) {
        elements.append(element)
    }

    @discardableResult
    mutating func pop() -> Element? {
        elements.popLast()
    }

    func peek() -> Element? {
        elements.last
    }
}
