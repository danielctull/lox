
extension Value: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .boolean(value): return value.description
        case let .number(value): return value.description
        case let .string(value): return value
        case let .callable(value): return value.description
        case .nil: return "nil"
        }
    }
}
