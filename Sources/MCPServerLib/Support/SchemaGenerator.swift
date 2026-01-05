import MCP

// This should get added to the mcp template
struct SchemaGenerator {
	let properties: [String: SchemaType]

	struct StringSchema: Generator {
		let defaultValue: String?
		let description: String?
		let validEnumCases: [String]?

		let isRequired: Bool
		let minLength: Int?
		let maxLength: Int?
		let regexPattern: String?

		func asValue() -> Value {
			var builder: [String: Value] = [:]
			builder["type"] = "string"

			if let description {
				builder["description"] = .string(description)
			}

			if let defaultValue {
				builder["default"] = .string(defaultValue)
			}

			if let minLength {
				builder["minLength"] = .int(minLength)
			}

			if let maxLength {
				builder["maxLength"] = .int(maxLength)
			}

			if let regexPattern {
				builder["pattern"] = .string(regexPattern)
			}

			if let validEnumCases {
				builder["enum"] = .array(validEnumCases.map(Value.string))
			}

			return .object(builder)
		}
	}

	struct BooleanSchema: Generator {
		let defaultValue: Bool?
		let description: String?

		let isRequired: Bool

		func asValue() -> Value {
			var builder: [String: Value] = [:]
			builder["type"] = "boolean"

			if let description {
				builder["description"] = .string(description)
			}

			if let defaultValue {
				builder["default"] = .bool(defaultValue)
			}

			return .object(builder)
		}
	}

	struct NumberSchema: Generator {
		let defaultValue: Double?
		let description: String?

		let isRequired: Bool
		let isInteger: Bool
		let minimum: Double?
		let maximum: Double?
		let exclusiveMin: Double?
		let exclusiveMax: Double?
		let multipleOf: Double?

		func asValue() -> Value {
			var builder: [String: Value] = [:]
			builder["type"] = isInteger ? "integer" : "number"

			if let description {
				builder["description"] = .string(description)
			}

			if let defaultValue {
				if isInteger, Double(Int(defaultValue)) == defaultValue {
					builder["default"] = .int(Int(defaultValue))
				} else {
					builder["default"] = .double(defaultValue)
				}
			}

			if let minimum {
				builder["minimum"] = .double(minimum)
			}

			if let maximum {
				builder["maximum"] = .double(maximum)
			}

			if let exclusiveMin {
				builder["exclusiveMinimum"] = .double(exclusiveMin)
			}

			if let exclusiveMax {
				builder["exclusiveMaximum"] = .double(exclusiveMax)
			}

			if let multipleOf {
				builder["multipleOf"] = .double(multipleOf)
			}

			return .object(builder)
		}
	}

	struct ArraySchema: Generator {
		let defaultValue: [DefaultValue]?
		let description: String?
		let item: SchemaType?

		let isRequired: Bool
		let minItems: Int?
		let maxItems: Int?
		let uniqueItems: Bool?

		func asValue() -> Value {
			var builder: [String: Value] = [:]
			builder["type"] = "array"

			if let description {
				builder["description"] = .string(description)
			}

			if let defaultValue {
				builder["default"] = .array(defaultValue.map { $0.asValue() })
			}

			if let item {
				switch item {
				case .string(let schema):
					builder["items"] = schema.asValue()
				case .boolean(let schema):
					builder["items"] = schema.asValue()
				case .number(let schema):
					builder["items"] = schema.asValue()
				case .object(let schema):
					builder["items"] = schema.asValue()
				case .array(let schema):
					builder["items"] = schema.asValue()
				}
			}

			if let minItems {
				builder["minItems"] = .int(minItems)
			}

			if let maxItems {
				builder["maxItems"] = .int(maxItems)
			}

			if let uniqueItems {
				builder["uniqueItems"] = .bool(uniqueItems)
			}

			return .object(builder)
		}
	}

	struct ObjectSchema: Generator {
		let defaultValue: [String: DefaultValue]?
		let description: String?
		let isRequired: Bool
		let properties: [String: SchemaType]?

		let additionalProperties: Bool?

		func asValue() -> Value {
			var builder: [String: Value] = [:]
			builder["type"] = "object"

			if let properties {
				let wrapped: [String: Value] = properties.reduce(into: .init(), { partialResult, pair in
					let key = pair.key
					let schemaType = pair.value
					switch schemaType {
					case .string(let schema):
						partialResult[key] = schema.asValue()
					case .boolean(let schema):
						partialResult[key] = schema.asValue()
					case .number(let schema):
						partialResult[key] = schema.asValue()
					case .object(let schema):
						partialResult[key] = schema.asValue()
					case .array(let schema):
						partialResult[key] = schema.asValue()
					}
				})
				builder["properties"] = .object(wrapped)
			}

			if let description {
				builder["description"] = .string(description)
			}

			if let defaultValue {
				builder["default"] = .object(defaultValue.mapValues { $0.asValue() })
			}

			if let additionalProperties {
				builder["additionalProperties"] = .bool(additionalProperties)
			}

			return .object(builder)
		}
	}

	enum SchemaType {
		case string(StringSchema)
		case boolean(BooleanSchema)
		case number(NumberSchema)
		case object(ObjectSchema)
		indirect case array(ArraySchema)
	}

	enum DefaultValue: Generator {
		case string(String)
		case number(Double)
		case boolean(Bool)
		indirect case array([DefaultValue])
		indirect case object([String: DefaultValue])

		func asValue() -> Value {
			switch self {
			case .string(let string):
					.string(string)
			case .number(let double):
				if Double(Int(double)) == double {
					.int(Int(double))
				} else {
					.double(double)
				}
			case .boolean(let bool):
					.bool(bool)
			case .array(let array):
					.array(array.map({ $0.asValue() }))
			case .object(let dictionary):
					.object(dictionary.mapValues({ $0.asValue() }))
			}
		}
	}

	var outputSchema: MCP.Value {
		let requiredArray = properties
			.filter {
				switch $0.value {
				case .string(let schema):
					schema.isRequired
				case .boolean(let schema):
					schema.isRequired
				case .number(let schema):
					schema.isRequired
				case .object(let schema):
					schema.isRequired
				case .array(let schema):
					schema.isRequired
				}
			}
			.map(\.key)
			.map(Value.string)

		let mappedProperties = properties
			.reduce(into: [String: Value]()) { dict, pair in
				let key = pair.key
				let schemaType = pair.value
				switch schemaType {
				case .string(let schema):
					dict[key] = schema.asValue()
				case .boolean(let schema):
					dict[key] = schema.asValue()
				case .number(let schema):
					dict[key] = schema.asValue()
				case .object(let schema):
					dict[key] = schema.asValue()
				case .array(let schema):
					dict[key] = schema.asValue()
				}
			}

		return .object([
			"type": "object",
			"properties": .object(mappedProperties),
			"required": .array(requiredArray)
		])
	}
}

extension SchemaGenerator {
	private protocol Generator {
		func asValue() -> Value
	}
}
