import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskView = ToolCommand(rawValue: "fingerstring-task-view")
}

struct TaskViewTool: ToolImplementation {
	static let command: ToolCommand = .taskView

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: View a task with all its details including note",
		inputSchema: SchemaGenerator(properties: [
			"hashID": .string(.init(description: "Hash ID of the task to view", isRequired: true))
		]).outputSchema)

	private let hashID: String

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let hashID = arguments.strings.hashID
		else { throw .missingArgument("hashID") }
		self.hashID = hashID
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let task = try await wrap(in: ContentError.self) {
			try await controller.getTask(hashID: hashID)
		}
		guard let task else {
			throw .contentError(message: "No task with hash '\(hashID)'")
		}

		struct TaskDetail: Codable {
			let id: String
			let label: String
			let isComplete: Bool
			let note: String?
		}

		let detail = TaskDetail(
			id: task.itemHashId,
			label: task.label,
			isComplete: task.isComplete,
			note: task.note)

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(hashID)",
			metaData: nil,
			content: [detail])
		.toResult()
	}
}
