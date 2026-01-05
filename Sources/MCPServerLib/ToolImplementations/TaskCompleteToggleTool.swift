import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let taskComplete = ToolCommand(rawValue: "fingerstring-task-complete")
}

struct TaskCompleteToggleTool: ToolImplementation {
	static let command: ToolCommand = .taskComplete

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Mark or unmark a task as completed",
		inputSchema: SchemaGenerator(properties: [
			"hashID": .string(.init(description: "Hash ID of the task", isRequired: true)),
			"mark": .boolean(.init(description: "Whether to mark as completed", defaultValue: true))
		]).outputSchema)

	private let hashID: String
	private let mark: Bool

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let hashID = arguments.strings.hashID
		else { throw .missingArgument("hashID") }
		self.hashID = hashID
		self.mark = arguments.bools.mark ?? true
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let task = try await wrap(in: ContentError.self) {
			try await controller.getTask(hashID: hashID)
		}
		guard let task else {
			throw .contentError(message: "Can't find or update task with hash '\(hashID)'")
		}

		let updated = try await wrap(in: ContentError.self) {
			try await controller.updateTask(id: task.id, isCompleted: .change(mark))
		}

		let completionSlug = updated.isComplete ? "completed" : "incomplete"

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(hashID)",
			metaData: nil,
			content: ["Marked task [\(updated.itemHashId)] (\(updated.label)) as \(completionSlug)"])
		.toResult()
	}
}
