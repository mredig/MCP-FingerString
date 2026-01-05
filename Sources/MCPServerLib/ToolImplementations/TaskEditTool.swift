import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskEdit = ToolCommand(rawValue: "fingerstring-task-edit")
}

struct TaskEditTool: ToolImplementation {
	static let command: ToolCommand = .taskEdit

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Edit a task's attributes like label or note",
		inputSchema: SchemaGenerator(properties: [
			"hashID": .string(.init(description: "Hash ID of the task to edit", isRequired: true)),
			"label": .string(.init(description: "New label for the task")),
			"note": .string(.init(description: "New note for the task"))
		]).outputSchema)

	private let hashID: String
	private let label: String?
	private let note: String?

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let hashID = arguments.strings.hashID
		else { throw .missingArgument("hashID") }
		self.hashID = hashID
		self.label = arguments.strings.label
		self.note = arguments.strings.note
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let task = try await wrap(in: ContentError.self) {
			try await controller.getTask(hashID: hashID)
		}
		guard let task else {
			throw .contentError(message: "No task with hash '\(hashID)'")
		}

		let updatedTask = try await wrap(in: ContentError.self) {
			try await controller.updateTask(
				id: task.id,
				label: label.map { .change($0) } ?? .unchanged,
				note: note.map { .change($0) } ?? .unchanged)
		}

		struct TaskDetail: Codable {
			let id: String
			let label: String
			let isComplete: Bool
			let note: String?
		}

		let detail = TaskDetail(
			id: updatedTask.itemHashId,
			label: updatedTask.label,
			isComplete: updatedTask.isComplete,
			note: updatedTask.note)

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(hashID)",
			metaData: nil,
			content: [detail])
		.toResult()
	}
}
