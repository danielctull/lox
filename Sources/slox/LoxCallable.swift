
protocol LoxCallable {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Value]) throws -> Value
}
