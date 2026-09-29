import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskMove = ToolCommand(rawValue: "fingerstring-task-move")
}

struct TaskMoveTool: ToolImplementation {
	static let command: ToolCommand = .taskMove

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Move a task, along with all of its subtasks, to the end of a list or to be a subtask of another task. ***IMPORTANT*** Immediately after using this tool, inform the user what was moved and where it went.",
		inputSchema: SchemaGenerator(properties: [
			"hashID": .string(.init(description: "Hash ID of the task to move", isRequired: true)),
			"query": .string(.init(description: "Slug of the destination list or hash ID of the new parent task", isRequired: true)),
			"queryType": .string(.init(description: "The type of the query. [slug|hashID]", isRequired: true, validEnumCases: ["slug", "hashID"])),
		]).outputSchema)

	private let hashID: String
	private let query: QueryType

	private enum QueryType {
		case list(slug: String)
		case task(hashID: String)
	}

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let hashID = arguments.strings.hashID,
			let query = arguments.strings.query,
			let queryType = arguments.strings.queryType
		else { throw .missingArgument("hashID, query, and queryType are required") }

		self.hashID = hashID

		switch queryType {
		case "slug":
			self.query = .list(slug: query)
		case "hashID":
			self.query = .task(hashID: query)
		default:
			throw .initializationFailed("Query type '\(queryType)' is invalid")
		}
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let task = try await wrap(in: ContentError.self) {
			try await controller.getTask(hashID: hashID)
		}
		guard let task else {
			throw .contentError(message: "No task with hash '\(hashID)'")
		}

		let parent: ListController.TaskParent
		let destination: String
		switch query {
		case .list(let slug):
			guard let list = try await wrap(in: ContentError.self, {
				try await controller.getList(withSlug: slug)
			}) else {
				throw .contentError(message: "List with slug '\(slug)' not found")
			}
			parent = .list(list.id)
			destination = "list '\(slug)'"
		case .task(let parentHashID):
			parent = .task(hashID: parentHashID)
			destination = "task '\(parentHashID)'"
		}

		try await wrap(in: ContentError.self) {
			try await controller.moveTask(task.id, to: parent)
		}

		let userMessage = "Moved task '\(task.label)' [\(task.itemHashId)] to \(destination)"

		return StructuredContentOutput(
			inputRequest: "\(self)",
			metaData: nil,
			content: [userMessage],
			userMessage: userMessage)
		.toResult()
	}
}
