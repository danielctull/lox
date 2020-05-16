
public struct Callable {
    public let description: String
    let arity: Int
    let call: (Interpreter, [Value]) throws -> Value
}
