import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskDelete = ToolCommand(rawValue: "fingerstring-task-delete")
}

struct TaskDeleteTool: ToolImplementation {
	static let command: ToolCommand = .taskDelete

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Delete a task. USE WITH EXTREME CAUTION: Never delete a task without confirming with the user first as this is destructive and CANNOT be recovered. You probably want to just mark it as completed.",
		inputSchema: SchemaGenerator(properties: [
			"hashID": .string(.init(description: "Hash ID of the task to delete", isRequired: true)),
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

		try await wrap(in: ContentError.self) {
			try await controller.deleteTask(task.id)
		}

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(hashID)",
			metaData: nil,
			content: ["Deleted \(task.label) [\(task.itemHashId)]"])
		.toResult()
	}
}
