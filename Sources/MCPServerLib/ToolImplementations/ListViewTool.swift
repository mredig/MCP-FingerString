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
			"showCompletedTasks": .boolean(.init(description: "Whether to show completed tasks", defaultValue: false)),
			"includeSubtasks": .boolean(.init(description: "Whether to show subtasks", defaultValue: true)),
			"offset": .number(.init(description: "The task index to start at.", defaultValue: 0, isInteger: true)),
			"limit": .number(.init(description: "How many tasks to allow showing", defaultValue: 25, isInteger: true)),
		]).outputSchema)

	private let slug: String
	private let showCompletedTasks: Bool
	private let includeSubtasks: Bool

	private let limit: Int
	private let offset: Int

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let slug = arguments.strings.slug
		else { throw .missingArgument("slug") }
		self.slug = slug
		self.showCompletedTasks = arguments.bools.showCompletedTasks ?? false
		self.includeSubtasks = arguments.bools.includeSubtasks ?? true
		self.limit = arguments.integers.limit ?? 10
		self.offset = arguments.integers.offset ?? 0
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

		var currentIndex = 0
		try await wrap(in: ContentError.self) {
			for try await (_, task) in itemsStream {
				guard task.isComplete == false || showCompletedTasks else { continue }
				defer { currentIndex += 1 }
				guard currentIndex >= offset else { continue }
				if tasks.count < limit {
					let output = try await buildTaskOutput(task, includeSubtasks: includeSubtasks, controller: controller)
					tasks.append(output)
				}
				// otherwise, continue the count
			}
		}

		struct Output: Codable {
			let title: String
			let description: String?
			let tasks: [TaskOutput]
		}

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(slug)",
			metaData: .init(resultCount: currentIndex),
			content: [Output(title: list.headerTitle, description: list.description, tasks: tasks)],
			userMessage: nil)
		.toResult()
	}

	struct TaskOutput: Codable {
		let id: String
		let label: String
		let isComplete: Bool
		let hasNote: Bool
		let subtasks: [TaskOutput]?
		let hasSubtasks: Bool?
	}

	private func buildTaskOutput(
		_ task: TaskItem,
		includeSubtasks: Bool,
		controller: ListController
	) async throws(ContentError) -> TaskOutput {

		var subtasks: [TaskOutput]? = nil

		if task.firstSubtaskId != nil && includeSubtasks {
			let stream = try await wrap(in: ContentError.self) {
				try await controller.getAllTasksStream(on: .task(hashID: task.itemHashId))
			}

			var subArray: [TaskOutput] = []
			try await wrap(in: ContentError.self) {
				for try await (_, subtask) in stream {
					guard task.isComplete == false || showCompletedTasks else { continue }

					let output = try await buildTaskOutput(subtask, includeSubtasks: true, controller: controller)
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
			subtasks: subtasks,
			hasSubtasks: includeSubtasks == false && task.firstSubtaskId != nil)
	}
}
