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
		description: "FingerString: Add one or more tasks to a list or as subtasks. Use notes to add context and anything that might be helpful. ***IMPORTANT*** Immediately after using this tool, inform the user what tasks were created and where they were added.",
		inputSchema: SchemaGenerator(properties: [
			"query": .string(.init(description: "Slug of the target list or hash ID of the parent task", isRequired: true)),
			"queryType": .string(.init(description: "The type of the query. [slug|hashID]", isRequired: true, validEnumCases: ["slug", "hashID"])),
			"tasks": .array(.init(
				description: "Array of tasks to add. Each task should have a label and optional note.",
				isRequired: true,
				item: .object(.init(
					properties: [
						"label": .string(.init(description: "Label for the task", isRequired: true)),
						"note": .string(.init(description: "Optional note for the task"))
					]
				)),
				minItems: 1
			))
		]).outputSchema)

	private let query: QueryType
	private let tasks: [TaskInput]

	private enum QueryType {
		case list(slug: String)
		case task(hashID: String)
	}
	
	private struct TaskInput {
		let label: String
		let note: String?
	}

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let query = arguments.strings.query,
			let queryType = arguments.strings.queryType
		else { throw .missingArgument("query and queryType are required") }

		switch queryType {
		case "slug":
			self.query = .list(slug: query)
		case "hashID":
			self.query = .task(hashID: query)
		default:
			throw .initializationFailed("Query type '\(queryType)' is invalid")
		}
		
		// Parse tasks array from arguments
		guard let tasksValue = arguments.arguments?["tasks"] else {
			throw .missingArgument("tasks array is required")
		}
		
		// Extract array from Value
		guard case .array(let taskValues) = tasksValue else {
			throw .mismatchedType(argument: "tasks", expected: "array")
		}
		
		// Parse each task object
		var parsedTasks: [TaskInput] = []
		for (index, taskValue) in taskValues.enumerated() {
			guard case .object(let taskObj) = taskValue else {
				throw .mismatchedType(argument: "tasks[\(index)]", expected: "object")
			}
			
			guard let labelValue = taskObj["label"], case .string(let label) = labelValue else {
				throw .missingArgument("tasks[\(index)].label is required")
			}
			
			let note: String?
			if let noteValue = taskObj["note"], case .string(let noteString) = noteValue {
				note = noteString
			} else {
				note = nil
			}
			
			parsedTasks.append(TaskInput(label: label, note: note))
		}
		
		guard !parsedTasks.isEmpty else {
			throw .initializationFailed("tasks array must contain at least one task")
		}
		
		self.tasks = parsedTasks
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		// Determine the parent
		let parent: ListController.TaskParent
		
		switch query {
		case .list(let slug):
			guard let list = try await wrap(in: ContentError.self, {
				try await controller.getList(withSlug: slug)
			}) else {
				throw ContentError.contentError(message: "List with slug '\(slug)' not found")
			}
			parent = .list(list.id)
		case .task(let hashID):
			parent = .task(hashID: hashID)
		}
		
		// Add all tasks and track results
		struct TaskResult {
			let label: String
			let hashID: String?
			let note: String?
			let status: String
			let error: String?
		}
		
		var results: [TaskResult] = []
		
		for taskInput in tasks {
			do {
				let createdTask = try await wrap(in: ContentError.self) {
					try await controller.createTask(label: taskInput.label, note: taskInput.note, on: parent)
				}
				
				results.append(TaskResult(
					label: createdTask.label,
					hashID: createdTask.itemHashId,
					note: createdTask.note,
					status: "created",
					error: nil
				))
			} catch {
				results.append(TaskResult(
					label: taskInput.label,
					hashID: nil,
					note: taskInput.note,
					status: "failed",
					error: "\(error)"
				))
			}
		}
		
		struct TaskOutput: Codable {
			let status: String
			let label: String
			let hashID: String?
			let note: String?
			let error: String?
		}
		
		let successCount = results.filter { $0.status == "created" }.count
		let failureCount = results.count - successCount
		
		let parentContext: String
		switch query {
		case .list(let slug):
			parentContext = "to list '\(slug)'"
		case .task(let hashID):
			parentContext = "as subtasks of '\(hashID)'"
		}
		
		let userMessage: String
		if failureCount == 0 {
			if results.count == 1 {
				userMessage = "Added task '\(results[0].label)' \(parentContext)"
			} else {
				userMessage = "Added \(successCount) tasks \(parentContext)"
			}
		} else {
			userMessage = "Added \(successCount) of \(results.count) tasks \(parentContext). \(failureCount) failed."
		}
		
		return StructuredContentOutput(
			inputRequest: "\(self)",
			metaData: .init(
				summary: userMessage,
				resultCount: results.count
			),
			content: results.map { result in
				TaskOutput(
					status: result.status,
					label: result.label,
					hashID: result.hashID,
					note: result.note,
					error: result.error
				)
			},
			userMessage: userMessage
		).toResult()
	}
}