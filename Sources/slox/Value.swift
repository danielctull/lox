
public enum Value {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case callable(Callable)
    case `nil`
}

extension Value {

    static func function(_ function: @escaping () throws -> Value) -> Value {
        .function(arity: 0, { _, _ in try function() })
    }

    static func function(
        arity: Int,
        _ function: @escaping (Interpreter, [Value]) throws -> Value
    ) -> Value {
        .callable(Callable(description: "<native function>",
                           arity: arity,
                           call: function))
    }
}
