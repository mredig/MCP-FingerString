import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let listInfo = ToolCommand(rawValue: "fingerstring-list-info")
}

struct ListInfoTool: ToolImplementation {
	static let command: ToolCommand = .listInfo

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: View info about a list like its description and task count",
		inputSchema: SchemaGenerator(properties: [
			"slug": .string(.init(description: "Slug of the list to view", isRequired: true)),
			"includeCompletedTasks": .boolean(.init(description: "Whether to show completed tasks", defaultValue: false)),
		]).outputSchema)

	private let slug: String
	private let includeCompletedTasks: Bool

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let slug = arguments.strings.slug
		else { throw .missingArgument("slug") }
		self.slug = slug
		self.includeCompletedTasks = arguments.bools.includeCompletedTasks ?? false
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let list = try await wrap(in: ContentError.self) {
			try await controller.getList(withSlug: slug)
		}
		guard let list else {
			throw .contentError(message: "No list with the slug '\(slug)'")
		}

		let itemsStream = try await wrap(in: ContentError.self) {
			try await controller.getAllTasksStream(on: .list(list.id))
		}

		var currentIndex = 0
		try await wrap(in: ContentError.self) {
			for try await (_, task) in itemsStream {
				guard task.isComplete == false || includeCompletedTasks else { continue }
				currentIndex += 1
				// otherwise, continue the count
			}
		}

		struct Output: Codable {
			let title: String
			let description: String?
			let taskCount: Int
		}

		return StructuredContentOutput(
			inputRequest: "\(ListInfoTool.command.rawValue): \(slug)",
			metaData: nil,
			content: [Output(title: list.headerTitle, description: list.description, taskCount: currentIndex)],
			userMessage: nil)
		.toResult()
	}
}
