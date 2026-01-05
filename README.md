# MCP-FingerString

A Swift MCP (Model Context Protocol) server for task list management, exposing FingerString's task operations as MCP tools and prompts.

## TLDR - Quick Start

**Install via Homebrew:**
Use brew to get the [pizza tool package](https://github.com/mredig/homebrew-pizza-mcp-tools), containing this (and other tools).

```bash
brew tap mredig/pizza-mcp-tools
brew update
brew install mcp-fingerstring
```

**Or build from source:**
```bash
git clone https://github.com/mredig/MCP-FingerString.git
cd MCP-FingerString
swift build -c release
```

**Add to Zed settings** (`~/.config/zed/settings.json`):
```json
{
  "fingerstring": {
    "command": "mcp-fingerstring",
    "args": [],
    "env": {}
  }
}
```

**Or Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "fingerstring": {
      "command": "/path/to/mcp-fingerstring"
    }
  }
}
```

## What It Does

Access and manage your task lists from within Claude or Zed. Use natural language to organize tasks, create subtasks, and manage your workflow without leaving your AI assistant.

**Common workflows:**
- "Create a project list for the new feature and add all the subtasks we discussed"
- "Show me all incomplete tasks across my lists"
- "Update the task about database migration with the new approach we discussed"
- "What tasks are blocking progress on the authentication feature?"

The AI automatically uses these tools to understand your task structure and help you stay organized.

## Available Tools

### List Tools
- **`list-view`** - View a list with all tasks and subtasks (recursive display)
- **`list-create`** - Create a new task list
- **`list-delete`** - Delete a list
- **`list-all`** - Show all lists

### Task Tools
- **`task-view`** - View task details including all subtasks
- **`task-add`** - Add a task to a list or as a subtask
- **`task-edit`** - Edit task label or note
- **`task-delete`** - Delete a task
- **`task-complete`** - Mark task complete/incomplete

### Prompts

Currently stashed (not yet working in MCP protocol). Use the template below instead:

## System Prompt Template

Add this to your system prompt or use as a custom instruction to guide the LLM's use of FingerString:

```
You have access to FingerString, a task management tool. Use it throughout our conversation to track work, keep notes, and maintain context across multiple interactions. (If you do not have access to these tools, notify the user as it is likely a permissions issue)

Task Management Guidelines:

1. **Create Lists as Projects**
   - Create a list for each major project or goal
   - Think of lists as projects, or even sub-projects within larger projects
   - Communicate the list name to the user when creating

2. **Add Tasks with Clear Success Criteria**
   - Keep task labels short (max ~10 words)
   - In task notes, include:
     - What constitutes success for this task
     - Any important details or context
     - Constraints or dependencies
   - Use tasks as persistent notes for ideas not yet ready to implement

3. **Structure with Subtasks**
   - Break large tasks into subtasks
   - Keep the hierarchy logical and navigable
   - Use subtasks to track implementation steps

4. **Track Progress**
   - Before completing a task, view it to verify success criteria are met
   - Only mark complete when genuinely finished
   - Periodically check task lists to stay aligned with goals

5. **Persistent Knowledge**
   - Use FingerString instead of relying solely on context window
   - Tasks persist across conversations and contexts
   - Important information stays structured and retrievable
   - Capture insights, patterns, and reminders that might otherwise be lost

6. **User Control**
   - The user can manage tasks via CLI commands if preferred
   - Respect their task structure and only modify as directed
   - Always communicate changes clearly
   - **IMPORTANT: List and task deletion is irreversible. Never delete without explicit user permission.**

7. **Deletion is Permanent**
   - `list-delete` and `task-delete` operations cannot be undone
   - Never assume permission to delete - always ask explicitly
   - When deletion is necessary, confirm with the user and summarize what will be lost
```

**How to use:**
1. Copy the template above
2. Add it to your system prompt or Claude instructions
3. The LLM will automatically use FingerString to track work throughout conversations

## Usage Examples

Ask natural language questions in Claude or Zed's assistant:

**"Create a list called 'Website Redesign' and break it into subtasks for design, frontend, and backend"**
- Uses `list-create` and `task-add` to structure the project

**"Show me all my tasks and help me prioritize what to work on next"**
- Uses `list-view` and `list-all` to understand your current workload

**"Update the authentication task with the security requirements we just discussed"**
- Uses `task-edit` to keep your tasks current

**"What subtasks are blocking the v2.0 release?"**
- Uses `list-view` to find incomplete tasks and identify blockers

## For Developers

Want to add your own tools? The codebase uses a clean registry pattern:

1. Create tool in `Sources/MCPServerLib/ToolImplementations/`
2. Implement `ToolImplementation` protocol  
3. Register in `ToolRegistry.swift`

See existing tools for examples. Each follows the same pattern: define schema, extract parameters, implement logic.

## Requirements

- Swift 6.0+ (development)
- macOS 13.0+

## Testing

```bash
swift test
```

## Technical Usage (for MCP clients)

If you're using this with other MCP clients:

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "fingerstring": {
      "command": "mcp-fingerstring"
    }
  }
}
```

**Other MCP Clients:** Point to the `mcp-fingerstring` binary and use the tools via their JSON-RPC interface.

## Related Projects

- **[FingerString](https://github.com/mredig/FingerString)** - CLI tool for task management. Use the MCP server above to integrate with Claude/Zed, or use the CLI directly for local management.

## Resources

- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
- [JSON Schema Reference](https://json-schema.org/understanding-json-schema/reference)
- [Homebrew Package](https://github.com/mredig/homebrew-pizza-mcp-tools)
