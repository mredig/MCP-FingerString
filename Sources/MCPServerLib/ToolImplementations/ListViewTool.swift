import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let listView = ToolCommand(rawValue: "fingerstring-list-view")
}

struct ListViewTool: ToolImplementation {
	static let command: ToolCommand = .listView

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: View a list and its items",
		inputSchema: SchemaGenerator(properties: [
			"slug": .string(.init(description: "Slug of the list to view", isRequired: true)),
			"showCompletedTasks": .boolean(.init(description: "Whether to show completed tasks", defaultValue: false))
		]).outputSchema)

	private let slug: String
	private let showCompletedTasks: Bool

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let slug = arguments.strings.slug
		else { throw .missingArgument("slug") }
		self.slug = slug
		self.showCompletedTasks = arguments.bools.showCompletedTasks ?? false
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

		var tasks: [TaskOutput] = []

		try await wrap(in: ContentError.self) {
			for try await (_, task) in itemsStream {
				guard task.isComplete == false || showCompletedTasks else { continue }
				let output = try await buildTaskOutput(task, controller: controller)
				tasks.append(output)
			}
		}

		struct Output: Codable {
			let title: String
			let description: String?
			let tasks: [TaskOutput]
		}

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(slug)",
			metaData: nil,
			content: [Output(title: list.headerTitle, description: list.description, tasks: tasks)])
		.toResult()
	}

	struct TaskOutput: Codable {
		let id: String
		let label: String
		let isComplete: Bool
		let hasNote: Bool
		let subtasks: [TaskOutput]?
	}

	private func buildTaskOutput(
		_ task: TaskItem,
		controller: ListController
	) async throws(ContentError) -> TaskOutput {

		var subtasks: [TaskOutput]? = nil

		if task.firstSubtaskId != nil {
			let stream = try await wrap(in: ContentError.self) {
				try await controller.getAllTasksStream(on: .task(hashID: task.itemHashId))
			}

			var subArray: [TaskOutput] = []
			try await wrap(in: ContentError.self) {
				for try await (_, subtask) in stream {
					guard task.isComplete == false || showCompletedTasks else { continue }

					let output = try await buildTaskOutput(subtask, controller: controller)
					subArray.append(output)
				}
			}

			if !subArray.isEmpty {
				subtasks = subArray
			}
		}

		return TaskOutput(
			id: task.itemHashId,
			label: task.label,
			isComplete: task.isComplete,
			hasNote: task.note != nil,
			subtasks: subtasks)
	}
}
