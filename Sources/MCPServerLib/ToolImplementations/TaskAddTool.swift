import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskAdd = ToolCommand(rawValue: "fingerstring-task-add")
}

struct TaskAddTool: ToolImplementation {
	static let command: ToolCommand = .taskAdd

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Add a task to a list or as a subtask. Use notes to add context and anything that might be helpful. As of this writing, tasks cannot be edited, so make sure to err on including too much detail in the note as you can't go back and add it (yet)",
		inputSchema: SchemaGenerator(properties: [
			"query": .string(.init(description: "Slug of the target list or hash ID of the parent task", isRequired: true)),
			"queryType": .string(.init(description: "The type of the query. [slug|hashID]", isRequired: true, validEnumCases: ["slug", "hashID"])),
			"label": .string(.init(description: "Label for the task", isRequired: true)),
			"note": .string(.init(description: "Optional note for the task"))
		]).outputSchema)

	private let query: QueryType
	private let label: String
	private let note: String?

	private enum QueryType {
		case list(slug: String)
		case task(hashID: String)
	}

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let query = arguments.strings.query,
			let label = arguments.strings.label,
			let queryType = arguments.strings.queryType
		else { throw .missingArgument("query and label are required") }
		self.label = label
		self.note = arguments.strings.note

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
			let parent: ListController.TaskParent

			switch query {
			case .list(let slug):
				guard
					let list = try await controller.getList(withSlug: slug)
				else { throw ContentError.contentError(message: "List with slug \(slug) not found") }
				parent = .list(list.id)
			case .task(let hashID):
				parent = .task(hashID: hashID)
			}

			return try await controller.createTask(label: label, note: note, on: parent)
		}

		struct TaskOutput: Codable {
			let status: String
			let label: String
			let hashID: String
			let note: String?
		}

		return StructuredContentOutput(
			inputRequest: "\(self)",
			metaData: nil,
			content: [
				TaskOutput(
					status: "created",
					label: task.label,
					hashID: task.itemHashId,
					note: task.note)
			]).toResult()

	}
}
