# <#MCP-Server#>

A minimal, well-structured Swift MCP (Model Context Protocol) server template.

## TLDR - Quick Start

**Install via Homebrew:** (macOS only)
Use brew to get the [pizza tool package](https://github.com/mredig/homebrew-pizza-mcp-tools), containing this (and other tools). (this is optimistic that the tool will be included in these tools)

```bash
brew tap <#YOUR_GITHUB_USERNAME#>/pizza-mcp-tools
brew update
brew install <#mcp-server#>
```

**Or build from source:**
```bash
# Clone and build
git clone <your-repo-url>
cd <#MCP-Server#>
swift build
```

**Add to Zed settings** (`~/.config/zed/settings.json`): (recommended)

(In Zed, `Add Custom Server` and provide the following snippet)
```json
{
  /// The name of your MCP server
  "<#mcp-server#>": {
    /// The command which runs the MCP server
    "command": "<#mcp-server#>", // if building yourself, you'll need to provide the whole path
    /// The arguments to pass to the MCP server
    "args": [],
    /// The environment variables to set
    "env": {}
  }
}
```

**or Claude Desktop**
```json
# Add to Claude Desktop config at:
# ~/Library/Application Support/Claude/claude_desktop_config.json
{
  "mcpServers": {
    "<#mcp-server#>": {
      "command": "/path/to/<#MCP-Server#>/.build/debug/<#mcp-server#>"
    }
  }
}

# Restart Claude Desktop - you're done!
```

## Branding the Template

This is a generic MCP server template. To customize it for your specific project, replace the following placeholder strings throughout the codebase:

### String Replacements

| Find | Replace With |
|------|--------------|
| `<#mcp-server#>` | Your executable name (e.g., `mcp-fingerstring`) |
| `MCPServer` | Your module name in PascalCase (e.g., `MCPFingerString`) |
| `MCPServerLib` | Your library module name (e.g., `MCPFingerStringLib`) |
| `<#MCP-Server#>` | Your display name (e.g., `MCP-FingerString`) |
| `<#com.mcp-server#>` | Your reverse domain identifier (e.g., `com.fingerstring.mcp`) |
| `<#mcp-server://#>` | Your custom URI scheme (e.g., `fingerstring://`) |

### Quick Find and Replace

Use this command to find all instances of the template strings:

```bash
# Find all occurrences of "<#mcp-server#>"
grep -r "mcp-server" --include="*.swift" --include="*.json" --include="Makefile" --include="README.md" Sources/ Tests/ *.json Makefile README.md 2>/dev/null

# Find all occurrences of "MCPServer"
grep -r "MCPServer" --include="*.swift" Sources/ Tests/ 2>/dev/null

# Find all occurrences of "<#com.mcp-server#>"
grep -r "com.mcp-server" --include="*.swift" Sources/ Tests/ 2>/dev/null
```

### Files to Update

The following files typically need customization:

1. **Package.swift** - Update package name `<#MCP-Server#>`, product name `<#mcp-server#>`, and target names
2. **README.md** - Update title, description, and examples (especially the `<#..#>` placeholders)
3. **Makefile** - Update executable name `<#mcp-server#>` and version display
4. **mcp-config.example.json** - Update server identifier `<#mcp-server#>` and command path
5. **Sources/MCPServerLib/Support/Entrypoint.swift** - Update server name `<#MCP-Server#>` and logger labels `<#com.mcp-server#>`
6. **Sources/MCPServerLib/Support/ServerHandlers.swift** - Update logger labels `<#com.mcp-server#>` and resource URIs `<#mcp-server://#>`
7. **Sources/MCPServer/MCPMain.swift** - Update struct name and imports
8. **Tests/MCPServerTests/** - Update class names, imports, and assertions

### Example: Branding for "FingerString"

```bash
# In your project directory, use sed to replace strings (macOS)
find . -type f \( -name "*.swift" -o -name "*.json" -o -name "Makefile" -o -name "README.md" \) -exec sed -i '' \
  -e 's/<#mcp-server#>/mcp-fingerstring/g' \
  -e 's/MCPServer/MCPFingerString/g' \
  -e 's/MCPServerLib/MCPFingerStringLib/g' \
  -e 's/<#MCP-Server#>/MCP-FingerString/g' \
  -e 's/<#com\.mcp-server#>/com.fingerstring/g' \
  -e 's/<#mcp-server:\/\/#>/fingerstring:\/\//g' \
  {} +
```

Or use your IDE's find-and-replace feature for a more interactive approach.

## Adding Your Own Tools

1. **Create a new file** in `Sources/MCPServerLib/ToolImplementations/`
2. **Extend `ToolCommand`** with your command name
3. **Implement `ToolImplementation` protocol**
4. **Add to registry** in `ToolRegistry.swift`

### Example: Adding a Calculator Tool

```swift
// CalculatorTool.swift
import MCP
import Foundation

extension ToolCommand {
    static let calculate = ToolCommand(rawValue: "calculate")
}

struct CalculatorTool: ToolImplementation {
    static let command: ToolCommand = .calculate
    
    // JSON Schema reference: https://json-schema.org/understanding-json-schema/reference
    static let tool = Tool(
        name: command.rawValue,
        description: "Performs basic arithmetic operations",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "operation": .object([
                    "type": "string",
                    "enum": .array([.string("add"), .string("subtract"), .string("multiply"), .string("divide")]),
                    "description": "The operation to perform"
                ]),
                "a": .object([
                    "type": "number",
                    "description": "First number"
                ]),
                "b": .object([
                    "type": "number",
                    "description": "Second number"
                ])
            ]),
            "required": .array([.string("operation"), .string("a"), .string("b")])
        ])
    )
    
    let operation: String
    let a: Double
    let b: Double
    
    init(arguments: CallTool.Parameters) throws(ContentError) {
        guard let operation = arguments.strings.operation else {
            throw .missingArgument("operation")
        }
        guard let a = arguments.doubles.a else {
            throw .missingArgument("a")
        }
        guard let b = arguments.doubles.b else {
            throw .missingArgument("b")
        }
        
        self.operation = operation
        self.a = a
        self.b = b
    }
    
    func callAsFunction() async throws(ContentError) -> CallTool.Result {
        let result: Double
        switch operation {
        case "add": result = a + b
        case "subtract": result = a - b
        case "multiply": result = a * b
        case "divide":
            guard b != 0 else {
                throw .contentError(message: "Division by zero")
            }
            result = a / b
        default:
            throw .contentError(message: "Unknown operation: \(operation)")
        }
        
        let output = StructuredContentOutput(
            inputRequest: "\(operation): \(a) and \(b)",
            metaData: nil,
            content: [["result": result]])
        
        return output.toResult()
    }
}
```

Then add to `ToolRegistry.swift`:
```swift
static let registeredTools: [ToolCommand: any ToolImplementation.Type] = [
    .echo: EchoTool.self,
    .getTimestamp: GetTimestampTool.self,
    .calculate: CalculatorTool.self,  // ← Add your tool here
]
```

That's it! Rebuild and your tool is available.

## Project Structure

```
MCP-Server/
├── Sources/MCPServerLib/
│   ├── ToolRegistry.swift              ← Register your tools here
│   ├── ToolCommand.swift                ← Tool command constants
│   ├── ToolImplementations/             ← Put your tools here
│   │   ├── ToolImplementation.swift     ← Protocol definition
│   │   ├── EchoTool.swift               ← Example tool
│   │   └── GetTimestampTool.swift       ← Example tool
│   └── Support/                         ← Implementation details (don't need to modify)
│       ├── ServerHandlers.swift
│       ├── ToolSupport.swift
│       └── ...
```

## Tool Implementation Pattern

Every tool follows the same pattern:

1. **Extend `ToolCommand`** - Define your command identifier
2. **Define `static let tool`** - MCP Tool definition with JSON Schema
3. **Extract parameters in `init`** - Validate and convert to typed properties
4. **Implement `callAsFunction`** - Your tool's business logic

### Parameter Extraction

Use the `ParamLookup` helpers to extract typed parameters:

```swift
arguments.strings.myStringParam    // String?
arguments.integers.myIntParam      // Int?
arguments.doubles.myDoubleParam    // Double?
arguments.bools.myBoolParam        // Bool?
```

### Error Handling

Throw `ContentError` for all tool errors:

```swift
throw .missingArgument("paramName")
throw .mismatchedType(argument: "paramName", expected: "string")
throw .initializationFailed("custom message")
throw .contentError(message: "custom error")
throw .other(someError)
```

## Requirements

- Swift 6.0+
- macOS 13.0+

## Testing

```bash
swift test
```

## Included Examples

### Tools
- `echo` - Echoes a message back (demonstrates parameter handling)
- `get-timestamp` - Returns current ISO 8601 timestamp (demonstrates no-parameter tools)

### Resources
- `mcp-server://status` - Server status (JSON)
- `mcp-server://welcome` - Welcome message (text)
- `mcp-server://config` - Server configuration (JSON)

## Resources

- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
- [JSON Schema Reference](https://json-schema.org/understanding-json-schema/reference)

## License

MIT License
